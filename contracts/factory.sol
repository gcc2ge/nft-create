pragma solidity 0.8.9;

import "interfaces/ifactory_721.sol";
import "interfaces/ifactory_1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract Factory is AccessControl {
    IFactory_721 factory_721;
    IFactory_1155 factory_1155;

    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");

    constructor(address _factory_721, address _factory_1155) public {
        factory_721 = IFactory_721(_factory_721);
        factory_1155 = IFactory_1155(_factory_1155);

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINT_ROLE, msg.sender);
    }

    function grantMinterRole(address to) public {
        grantRole(MINT_ROLE, to);
    }

    function reovkeMinterRole(address to) public {
        revokeRole(MINT_ROLE, to);
    }

    function createToken_721(
        string memory _name,
        string memory _symbol,
        string memory _ipfs_uri,
        string memory _me_uri,
        string memory _salt,
        bytes memory _signature
    ) external {
        factory_721.createToken(
            _name,
            _symbol,
            _ipfs_uri,
            _me_uri,
            _salt,
            _signature
        );
    }

    function createToken_1155(
        string memory _name,
        string memory _symbol,
        string memory _ipfs_uri,
        string memory _me_uri,
        string memory _salt,
        bytes memory _signature
    ) external {
        factory_1155.createToken(
            _name,
            _symbol,
            _ipfs_uri,
            _me_uri,
            _salt,
            _signature
        );
    }

    function mint_1155(
        address _nft1155,
        address _receiver,
        uint256 _id,
        uint256 _quantities
    ) external onlyRole(MINT_ROLE) {
        factory_1155.mint_1155(
            _nft1155,
            _receiver,
            _id,
            _quantities
        );
    }

    function mintBatch_1155(
        address _nft1155,
        address _receiver,
        uint256[] calldata _ids,
        uint256[] calldata _quantities
    ) external onlyRole(MINT_ROLE) {
        factory_1155.mintBatch_1155(
            _nft1155,
            _receiver,
            _ids,
            _quantities
        );
    }

    function mint_721(
        address _nft721, address _to
    ) external onlyRole(MINT_ROLE) {
        factory_721.mint_721(_nft721, _to);
    }

    function mintBatch_721(
        address _nft721,
        address _to,
        uint256 _quantity
    ) external onlyRole(MINT_ROLE) {
        factory_721.mintBatch_721(_nft721, _to, _quantity);
    }
}
