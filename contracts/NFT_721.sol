pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "chiru-labs/ERC721A@4.0.0/contracts/ERC721A.sol";

contract NFT721 is ERC721A, AccessControl {
    event Migrate(uint256 snapshot_tokenId, string uri);

    using Strings for uint256;

    // ipfs uri
    string private _ipfs_baseuri;

    // me uri
    string private _me_baseuri;
    uint256 snapshot_tokenId;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(
        string memory name,
        string memory symbol,
        string memory _ipfs_uri,
        string memory _me_uri
    ) public ERC721A(name, symbol) {
        _ipfs_baseuri = _ipfs_uri;
        _me_baseuri = _me_uri;

        _setupRole(DEFAULT_ADMIN_ROLE, tx.origin);
        _setupRole(OPERATOR_ROLE, tx.origin);
        _setupRole(MINTER_ROLE, tx.origin);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function setBaseMeURI(string calldata _uri)
        external
        onlyRole(OPERATOR_ROLE)
    {
        _me_baseuri = _uri;
    }

    function mint(address _to) external onlyRole(MINTER_ROLE) {
        _safeMint(_to, 1);
    }

    function mintBatch(address _to, uint256 _quantity)
        external
        onlyRole(MINTER_ROLE)
    {
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

        string memory base;
        if (tokenId < snapshot_tokenId) {
            base = _ipfs_baseuri;
        } else {
            base = _me_baseuri;
        }

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return "";
        }

        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
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
        override(ERC721A, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function migrate(string memory _ipfs_uri) public onlyRole(OPERATOR_ROLE) {
        snapshot_tokenId = _nextTokenId();
        _ipfs_uri = _ipfs_uri;

        emit Migrate(snapshot_tokenId, _ipfs_uri);
    }
}
