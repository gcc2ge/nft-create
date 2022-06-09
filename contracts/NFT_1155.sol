pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT1155 is ERC1155, AccessControl {
    // NFT name
    string public name;

    // NFT symbol
    string public symbol;

    // ipfs uri
    string private _ipfs_baseuri;

    // me uri
    string private _me_baseuri;

    uint256 snapshot_tokenId;
    uint256 curr_tokenId;

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

    function setBaseMeURI(string calldata _uri)
        external
        onlyRole(OPERATOR_ROLE)
    {
        _me_baseuri = _uri;
    }

    function uri(uint256 _id) public view override returns (string memory) {
        string memory baseUri;

        if (_id <= snapshot_tokenId) {
            baseUri = _ipfs_baseuri;
        } else {
            baseUri = _me_baseuri;
        }

        return string(abi.encodePacked(baseUri, _id));
    }

    function mint(
        address _receiver,
        uint256 _id,
        uint256 _quantities
    ) external onlyRole(MINTER_ROLE) {
        if (_id > curr_tokenId) {
            curr_tokenId = _id;
        }
        _mint(_receiver, _id, _quantities, new bytes(0));
    }

    function mintBatch(
        address _receiver,
        uint256[] calldata _ids,
        uint256[] calldata _quantities
    ) external onlyRole(MINTER_ROLE) {
        require(_ids.length == _quantities.length, "Mismatched array lengths");
        for (uint256 i = 0; i < _ids.length; i++) {
            if (_ids[i] > curr_tokenId) {
                curr_tokenId = _ids[i];
            }
        }

        _mintBatch(_receiver, _ids, _quantities, new bytes(0));
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

        for (index = 0; index < curr_tokenId; index++) {
            uint256 balance = balanceOf(_owner, index + 1);
            if (balance > 0) {
                tokenCount += 1;
            }
        }

        uint256[] memory result = new uint256[](tokenCount);
        uint256 index2;
        for (index = 0; index < curr_tokenId; index++) {
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

    function migrate(string memory _ipfs_uri) public onlyRole(OPERATOR_ROLE) {
        snapshot_tokenId = curr_tokenId;
        _ipfs_uri = _ipfs_uri;
    }
}
