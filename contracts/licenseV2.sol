// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract MyERC721EnumerableUpgradeableV2 is
    Initializable,
    ERC721EnumerableUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    string private baseURI;
    address public owner;
    using Strings for uint256;

    event Minted(address indexed to, uint256 indexed id);
    event Burned(address indexed from, uint256 indexed id);
    event AdminTransfer(address indexed from, address indexed to, uint256 indexed id);
    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // New state variable for storing token creation times
    mapping(uint256 => uint256) private _tokenCreationTimes;

    function initialize() public initializer {
        __ERC721Enumerable_init();
        __ERC721_init("MyToken", "TOKEN");
        __AccessControl_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        owner = msg.sender;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return ownerOf(tokenId) != address(0);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721EnumerableUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    function mint(address to, uint256 id) public onlyRole(ADMIN_ROLE) {
        _mint(to, id);
        _tokenCreationTimes[id] = block.timestamp;  // Recording the creation time
        emit Minted(to, id);
    }

    function burn(address from, uint256 id) public onlyRole(ADMIN_ROLE) {
        require(ownerOf(id) == from, "Specified address is not the owner of the token");
        _burn(id);
        emit Burned(from, id);
    }

    function adminTransfer(address from, address to, uint256 id) public onlyRole(ADMIN_ROLE) {
        require(_exists(id), "Token ID does not exist");  // Check if token exists
        burn(from, id);
        mint(to, id);
        emit AdminTransfer(from, to, id);
    }

    function addAdmin(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(ADMIN_ROLE, account);
        emit AdminAdded(account);
    }

    function removeAdmin(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(ADMIN_ROLE, account);
        emit AdminRemoved(account);
    }

    function setBaseURI(string memory newBaseURI) public onlyRole(ADMIN_ROLE) {
        baseURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token ID does not exist");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override(ERC721Upgradeable, IERC721) onlyRole(ADMIN_ROLE) {
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721Upgradeable, IERC721) onlyRole(ADMIN_ROLE) {
        super.transferFrom(from, to, tokenId);
    }

    function transferOwnership(address newOwner) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newOwner != address(0), "New owner cannot be the zero address");
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        _revokeRole(ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, newOwner);
        owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }

    // New function to access the creation time of a token
    function getTokenCreationTime(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId), "Token does not exist");
        return _tokenCreationTimes[tokenId];
    }
}
