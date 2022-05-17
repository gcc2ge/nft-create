pragma solidity 0.8.9;

import "@openzeppelin-contracts/contracts/utils/CountersUpgradeable.sol";
import "@openzeppelin-contracts/contracts/utils/StringsUpgradeable.sol";
import "@openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin-contracts/contracts/access/AccessControlUpgradeable.sol";
import "@openzeppelin-contracts/contracts/utils/cryptography/ECDSAUpgradeable.sol";

contract NFT721Default is
    ERC721EnumerableUpgradeable,
    AccessControlUpgradeable
{
    event SignerUpdated(address newSigner);

    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;

    // base uri
    string private baseuri;

    using ECDSAUpgradeable for bytes32;
    address private _signer;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function __NFT721_init(
        string memory name,
        string memory symbol,
        string memory _baseuri
    ) public initializer {
        __AccessControl_init();
        __ERC721_init(name, symbol);

        __NFT721_init_unchained(_baseuri);
    }

    function __NFT721_init_unchained(string memory _baseuri)
        public
        initializer
    {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);

        baseuri = _baseuri;
    }

    function setSigner(address _newSigner) public onlyRole(OPERATOR_ROLE) {
        _signer = _newSigner;

        emit SignerUpdated(_signer);
    }

    function setBaseURI(string calldata _uri) external onlyRole(OPERATOR_ROLE) {
        baseuri = _uri;
    }

    function _hash(
        address _addr,
        address _receiver,
        string memory _tokenURI,
        string memory _salt
    ) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(_addr, _receiver, _tokenURI, _salt));
    }

    modifier onlySigner(
        address _receiver,
        string memory _tokenURI,
        string memory _salt,
        bytes memory _signature
    ) {
        bytes32 hash = _hash(msg.sender, _receiver, _tokenURI, _salt);
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
        address _to,
        string memory _tokenURI,
        string memory _salt,
        bytes memory _signature
    ) external onlySigner(_to, _tokenURI, _salt, _signature) returns (uint256) {
        return _mint_interal(_to, _tokenURI);
    }

    function _mint_interal(address _to, string memory _tokenURI)
        internal
        returns (uint256)
    {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(_to, newItemId);
        _setTokenURI(newItemId, _tokenURI);

        return newItemId;
    }

    function mintBatch(
        address _to,
        string[] memory tokenURIs,
        string memory _salt,
        bytes memory _signature
    ) external onlySignerBatch(_to, _salt, _signature) {
        // require(tos.length == tokenURIs.length, "error");
        for (uint256 i = 0; i < tokenURIs.length; i++) {
            _mint_interal(_to, tokenURIs[i]);
        }
    }

    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseuri;

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return
            string(
                abi.encodePacked(base, StringsUpgradeable.toString(tokenId))
            );
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory tokens)
    {
        uint256 tokenLength = ERC721Upgradeable.balanceOf(owner);
        tokens = new uint256[](tokenLength);
        for (uint256 i = 0; i < tokenLength; i++) {
            tokens[i] = ERC721EnumerableUpgradeable.tokenOfOwnerByIndex(
                owner,
                i
            );
        }
    }

    function grantMinterRole(address to) public {
        grantRole(MINTER_ROLE, to);
    }

    function reovkeMinterRole(address to) public {
        revokeRole(MINTER_ROLE, to);
    }

    function grantOperatorRole(address to) public {
        grantRole(OPERATOR_ROLE, to);
    }

    function reovkeOperatorRole(address to) public {
        revokeRole(OPERATOR_ROLE, to);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721EnumerableUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
