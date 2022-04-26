pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT1155 is ERC1155, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // NFT name
    string public name;

    // NFT symbol
    string public symbol;

    // ipfs uri
    string private _ipfs_baseuri;

    // me uri
    string private _me_baseuri;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;
    mapping(string => uint256) private _uriTokenId;
    mapping(uint256 => uint256) private _tokenId_type;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _ipfs_uri,
        string memory _me_uri
    ) public ERC1155("") {
        name = _name;
        symbol = _symbol;

        _setupRole(DEFAULT_ADMIN_ROLE, tx.origin);
        _setupRole(OPERATOR_ROLE, tx.origin);
        _setupRole(MINTER_ROLE, tx.origin);
        _setupRole(MINTER_ROLE, msg.sender);

        _ipfs_baseuri = _ipfs_uri;
        _me_baseuri = _me_uri;
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

    function uri(uint256 id) public view override returns (string memory) {
        uint256 token_type = _tokenId_type[id];
        string memory baseUri;
        string memory _tokenURI = _tokenURIs[id];
        if (token_type == 1) {
            baseUri = _ipfs_baseuri;
        } else if (token_type == 2) {
            baseUri = _me_baseuri;
        } else {
            revert("unknown  id");
        }

        return string(abi.encodePacked(baseUri, _tokenURI));
    }

    function mint(
        address receiver,
        string memory _tokenURI,
        uint256 quantities,
        uint256 token_type
    ) external onlyRole(MINTER_ROLE) {
        uint256 tokenId = _uriTokenId[_tokenURI];
        uint256 _id;
        if (tokenId == 0) {
            _tokenIds.increment();
            _id = _tokenIds.current();
            _setTokenURI(_id, _tokenURI);
            _setTokenId_type(_id, token_type);
        } else {
            _id = tokenId;
        }

        _mint(receiver, _id, quantities, new bytes(0));
    }

    function mintBatch(
        address receiver,
        string[] memory _tokenURIs_batch,
        uint256[] calldata quantities,
        uint256[] calldata token_types
    ) external onlyRole(MINTER_ROLE) {
        require(
            _tokenURIs_batch.length == quantities.length,
            "Mismatched array lengths"
        );

        require(
            _tokenURIs_batch.length == token_types.length,
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
                _setTokenId_type(newItemId, token_types[i]);
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
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _setTokenId_type(uint256 tokenId, uint256 tokenType)
        internal
        virtual
    {
        _tokenId_type[tokenId] = tokenType;
    }

    function migrate_tokenURI(uint256 tokenId, uint256 tokenType)
        external
        onlyRole(OPERATOR_ROLE)
    {
        _setTokenId_type(tokenId, tokenType);
    }
}
