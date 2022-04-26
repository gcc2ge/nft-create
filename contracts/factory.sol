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
        address nft1155,
        address receiver,
        string memory _tokenURI,
        uint256 quantities,
        uint256 token_type
    ) external onlyRole(MINT_ROLE) {
        factory_1155.mint_1155(
            nft1155,
            receiver,
            _tokenURI,
            quantities,
            token_type
        );
    }

    function mintBatch_1155(
        address nft1155,
        address receiver,
        string[] memory _tokenURIs_batch,
        uint256[] calldata quantities,
        uint256[] calldata token_types
    ) external onlyRole(MINT_ROLE) {
        factory_1155.mintBatch_1155(
            nft1155,
            receiver,
            _tokenURIs_batch,
            quantities,
            token_types
        );
    }

    function mint_721(
        address nft721,
        address _to,
        string memory _tokenURI,
        uint256 token_type
    ) external onlyRole(MINT_ROLE) {
        factory_721.mint_721(nft721, _to, _tokenURI, token_type);
    }

    function mintBatch_721(
        address nft721,
        address to,
        string[] memory tokenURIs,
        uint256[] calldata token_types
    ) external onlyRole(MINT_ROLE) {
        factory_721.mintBatch_721(nft721, to, tokenURIs, token_types);
    }
}
