pragma solidity 0.8.9;

import "@openzeppelin-contracts/contracts/access/AccessControlUpgradeable.sol";
import "@openzeppelin-contracts/contracts/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin-contracts/contracts/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin-contracts/contracts/utils/StringsUpgradeable.sol";
import "@openzeppelin-contracts/contracts/utils/CountersUpgradeable.sol";
import "@openzeppelin-contracts/contracts/utils/cryptography/ECDSAUpgradeable.sol";

contract NFT1155Default is ERC1155Upgradeable, AccessControlUpgradeable {
    event SignerUpdated(address newSigner);

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR");
    bytes32 public constant MINT_ROLE = keccak256("MINT_MANAGER");

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;

    using ECDSAUpgradeable for bytes32;
    address private _signer;

    mapping(string => uint256) private _uriTokenId;
    mapping(uint256 => string) private _tokenURIs;

    // NFT name
    string public name;

    // NFT symbol
    string public symbol;

    function GrantMintRole(address account) external onlyAdmin {
        grantRole(MINT_ROLE, account);
    }

    function RevokeMintOperator(address account) external onlyAdmin {
        revokeRole(MINT_ROLE, account);
    }

    function GrantOperatorRole(address account) external onlyAdmin {
        grantRole(OPERATOR_ROLE, account);
    }

    function RevokeOperator(address account) external onlyAdmin {
        revokeRole(OPERATOR_ROLE, account);
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "not admin");
        _;
    }

    modifier onlyMintRole() {
        require(hasRole(MINT_ROLE, msg.sender), "not minter");
        _;
    }

    modifier onlyOperatorRole() {
        require(hasRole(OPERATOR_ROLE, msg.sender), "not operator");
        _;
    }

    function __NFT1155_init(
        string memory _name,
        string memory _symbol,
        string memory _uri
    ) public initializer {
        __ERC1155_init(_uri);
        __AccessControl_init();

        __NFT1155_init_unchained(_name, _symbol);
    }

    function __NFT1155_init_unchained(
        string memory _name,
        string memory _symbol
    ) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
        _setupRole(MINT_ROLE, msg.sender);

        name = _name;
        symbol = _symbol;
    }

    function setSigner(address _newSigner) public onlyRole(OPERATOR_ROLE) {
        _signer = _newSigner;

        emit SignerUpdated(_signer);
    }

    function setBaseURI(string calldata _uri) external onlyOperatorRole {
        _setURI(_uri);
    }

    function uri(uint256 id) public view override returns (string memory) {
        string memory _tokenURI = _tokenURIs[id];

        string memory baseUri = super.uri(0);
        return
            string(abi.encodePacked(baseUri, StringsUpgradeable.toString(id)));
    }

    function _hash(
        address _addr,
        address _receiver,
        string memory _tokenURI,
        uint256 _quantities,
        string memory _salt
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _addr,
                    _receiver,
                    _tokenURI,
                    _quantities,
                    _salt
                )
            );
    }

    modifier onlySigner(
        address _receiver,
        string memory _tokenURI,
        uint256 _quantities,
        string memory _salt,
        bytes memory _signature
    ) {
        bytes32 hash = _hash(
            msg.sender,
            _receiver,
            _tokenURI,
            _quantities,
            _salt
        );
        bytes32 message = hash.toEthSignedMessageHash();
        require(message.recover(_signature) == _signer, "error sig");
        _;
    }

    function _hash_batch(
        address _addr,
        address _receiver,
        string memory _salt
    ) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(_addr, _receiver, _salt));
    }

    modifier onlySignerBatch(
        address _receiver,
        string memory _salt,
        bytes memory _signature
    ) {
        bytes32 hash = _hash_batch(msg.sender, _receiver, _salt);
        bytes32 message = hash.toEthSignedMessageHash();
        require(message.recover(_signature) == _signer, "error sig");
        _;
    }

    function mint(
        address receiver,
        string memory _tokenURI,
        uint256 quantities,
        string memory _salt,
        bytes memory _signature
    ) external onlySigner(receiver, _tokenURI, quantities, _salt, _signature) {
        uint256 tokenId = _uriTokenId[_tokenURI];
        uint256 _id;
        if (tokenId == 0) {
            _tokenIds.increment();
            _id = _tokenIds.current();
            _setTokenURI(_id, _tokenURI);
        } else {
            _id = tokenId;
        }

        _mint(receiver, _id, quantities, new bytes(0));
    }

    function mintBatch(
        address receiver,
        string[] memory _tokenURIs_batch,
        uint256[] calldata quantities,
        string memory _salt,
        bytes memory _signature
    ) external onlySignerBatch(receiver, _salt, _signature) {
        require(
            _tokenURIs_batch.length == quantities.length,
            "Mismatched array lengths"
        );

        uint256[] memory ids = new uint256[](_tokenURIs_batch.length);
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 tokenId = _uriTokenId[_tokenURIs_batch[i]];
            if (tokenId == 0) {
                _tokenIds.increment();
                uint256 newItemId = _tokenIds.current();
                ids[i] = newItemId;
                _setTokenURI(newItemId, _tokenURIs_batch[i]);
            } else {
                ids[i] = tokenId;
            }
        }

        _mintBatch(receiver, ids, quantities, new bytes(0));
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory ownerTokens)
    {
        uint256 index;
        uint256 tokenCount = 0;

        for (index = 0; index < _tokenIds.current(); index++) {
            uint256 balance = balanceOf(_owner, index + 1);
            if (balance > 0) {
                tokenCount += 1;
            }
        }

        uint256[] memory result = new uint256[](tokenCount);
        uint256 index2;
        for (index = 0; index < _tokenIds.current(); index++) {
            uint256 balance = balanceOf(_owner, index + 1);
            if (balance > 0) {
                result[index2] = index + 1;
                index2 += 1;
            }
        }
        return result;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        _tokenURIs[tokenId] = _tokenURI;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AccessControlUpgradeable, ERC1155Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
