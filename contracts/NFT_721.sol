pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract NFT721 is ERC721Enumerable, AccessControl {
    using Strings for uint256;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // ipfs uri
    string private _ipfs_baseuri;

    // me uri
    string private _me_baseuri;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => uint256) private _tokenId_type;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(
        string memory name,
        string memory symbol,
        string memory _ipfs_uri,
        string memory _me_uri
    ) public ERC721(name, symbol) {
        _ipfs_baseuri = _ipfs_uri;
        _me_baseuri = _me_uri;

        _setupRole(DEFAULT_ADMIN_ROLE, tx.origin);
        _setupRole(OPERATOR_ROLE, tx.origin);
        _setupRole(MINTER_ROLE, tx.origin);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function setBaseIpfsURI(string calldata _uri)
        external
        onlyRole(OPERATOR_ROLE)
    {
        _ipfs_baseuri = _uri;
    }

    function setBaseMeURI(string calldata _uri)
        external
        onlyRole(OPERATOR_ROLE)
    {
        _me_baseuri = _uri;
    }

    function mint(
        address _to,
        string memory _tokenURI,
        uint256 token_type
    ) external onlyRole(MINTER_ROLE) returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(_to, newItemId);
        _setTokenURI(newItemId, _tokenURI);
        _setTokenId_type(newItemId, token_type);

        return newItemId;
    }

    function mintBatch(
        address to,
        string[] memory tokenURIs,
        uint256[] calldata token_types
    ) external onlyRole(MINTER_ROLE) returns (uint256) {
        // require(tos.length == tokenURIs.length, "error");
        for (uint256 i = 1; i <= tokenURIs.length; i++) {
            this.mint(to, tokenURIs[i], token_types[i]);
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
        string memory base;

        uint256 token_type = _tokenId_type[tokenId];
        if (token_type == 1) {
            base = _ipfs_baseuri;
        } else if (token_type == 2) {
            base = _me_baseuri;
        } else {
            revert("unknown  id");
        }

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    function _setTokenId_type(uint256 tokenId, uint256 tokenType)
        internal
        virtual
    {
        _tokenId_type[tokenId] = tokenType;
    }

    function tokensOfOwner(address owner)
        public
        view
        returns (uint256[] memory tokens)
    {
        uint256 tokenLength = super.balanceOf(owner);
        tokens = new uint256[](tokenLength);
        for (uint256 i = 0; i < tokenLength; i++) {
            tokens[i] = ERC721Enumerable.tokenOfOwnerByIndex(owner, i);
        }
    }

    function transferOwner(address to) public {
        grantRole(DEFAULT_ADMIN_ROLE, to);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
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
        override(ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function migrate_tokenURI(uint256 tokenId, uint256 tokenType)
        external
        onlyRole(OPERATOR_ROLE)
    {
        _setTokenId_type(tokenId, tokenType);
    }
}
