pragma solidity 0.8.9;

import "@openzeppelin-contracts/contracts/utils/StringsUpgradeable.sol";
import "@openzeppelin-contracts/contracts/access/AccessControlUpgradeable.sol";
import "@openzeppelin-contracts/contracts/utils/cryptography/ECDSAUpgradeable.sol";

import "chiru-labs/ERC721A-Upgradeable@4.0.0/contracts/ERC721AUpgradeable.sol";

contract MeNFT721Creation is ERC721AUpgradeable, AccessControlUpgradeable {
    event SignerUpdated(address newSigner);
    event BaseURIUpdated(string uri);

    // base uri
    string private baseuri;

    using ECDSAUpgradeable for bytes32;
    address private _signer;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function __NFT721_init(
        string memory name,
        string memory symbol,
        string memory _baseuri
    ) public initializerERC721A initializer {
        __AccessControl_init();
        __ERC721A_init(name, symbol);

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

        emit BaseURIUpdated(_uri);
    }

    function _hash(
        address _addr,
        address _receiver,
        uint256 _quantity,
        string memory _salt
    ) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(_addr, _receiver, _quantity, _salt));
    }

    modifier onlySigner(
        address _receiver,
        uint256 _quantity,
        string memory _salt,
        bytes memory _signature
    ) {
        bytes32 hash = _hash(msg.sender, _receiver, _quantity, _salt);
        bytes32 message = hash.toEthSignedMessageHash();
        require(message.recover(_signature) == _signer, "error sig");
        _;
    }

    function mint(
        address _to,
        string memory _salt,
        bytes memory _signature
    ) external onlySigner(_to, 1, _salt, _signature) {
        _safeMint(_to, 1);
    }

    function mintBatch(
        address _to,
        uint256 _quantity,
        string memory _salt,
        bytes memory _signature
    ) external onlySigner(_to, _quantity, _salt, _signature) {
        // require(tos.length == tokenURIs.length, "error");
        _safeMint(_to, _quantity);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId, true);
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

        string memory base = baseuri;

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return "";
        }

        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, StringsUpgradeable.toString(tokenId)));
    }

    function tokensOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 balance = balanceOf(_owner);
        uint256[] memory tokens = new uint256[](balance);
        uint256 index;
        unchecked {
            uint256 totalSupply = totalSupply();
            for (uint256 i; i < totalSupply; i++) {
                if (ownerOf(i) == _owner) {
                    tokens[index] = uint256(i);
                    index++;
                }
            }
        }
        return tokens;
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
        override(ERC721AUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
