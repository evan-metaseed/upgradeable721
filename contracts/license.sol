// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing necessary modules from OpenZeppelin
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Declaring the main contract which extends OpenZeppelin's upgradeable ERC721Enumerable, Access Control, and other utilities.
contract MyERC721EnumerableUpgradeable is
    Initializable,
    ERC721EnumerableUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    // Defining the ADMIN_ROLE for role-based access control
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Variable for storing the base URI for metadata
    string private baseURI;

    // Variable for the contract owner
    address public owner;

    // Importing utility for string operations
    using Strings for uint256;

    // Events for token minting, burning, admin transfers, and ownership transfer
    event Minted(address indexed to, uint256 indexed id);
    event Burned(address indexed from, uint256 indexed id);
    event AdminTransfer(address indexed from, address indexed to, uint256 indexed id);
    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Contract initialization function replacing a constructor for upgradeable contracts.
    function initialize() public initializer {
        __ERC721Enumerable_init();
        __ERC721_init("MyToken", "TOKEN");
        __AccessControl_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        // Setting the deployer as the initial owner and admin
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        owner = msg.sender;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return ownerOf(tokenId) != address(0);
    }

    /// @notice Function to check if the contract supports a particular interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @return True if the contract supports the interface, false otherwise
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721EnumerableUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Internal function to authorize upgrades
    /// @param newImplementation The address of the new implementation
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /// @notice Function to mint a new token
    /// @param to The address of the recipient
    /// @param id The token ID to mint
    function mint(address to, uint256 id) public onlyRole(ADMIN_ROLE) {
        _mint(to, id);
        emit Minted(to, id);
    }

    /// @notice Function to burn a token
    /// @param from The address from which the token will be burned
    /// @param id The token ID to burn
    function burn(address from, uint256 id) public onlyRole(ADMIN_ROLE) {
        require(ownerOf(id) == from, "Specified address is not the owner of the token");
        _burn(id);
        emit Burned(from, id);
    }

    /// @notice Function to transfer a token by an admin (burn and re-mint)
    /// @param from The address from which the token will be burned
    /// @param to The address to which the token will be minted
    /// @param id The token ID to transfer
    function adminTransfer(address from, address to, uint256 id) public onlyRole(ADMIN_ROLE) {
        burn(from, id);
        mint(to, id);
        emit AdminTransfer(from, to, id);
    }

    /// @notice Grants the admin role to a specified account
    /// @param account The address to grant the admin role to
    function addAdmin(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(ADMIN_ROLE, account);
        emit AdminAdded(account);
    }

    /// @notice Revokes the admin role from a specified account
    /// @param account The address to revoke the admin role from
    function removeAdmin(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(ADMIN_ROLE, account);
        emit AdminRemoved(account);
    }

    /// @notice Sets the base URI for computing {tokenURI}
    /// @param newBaseURI The new base URI to set
    function setBaseURI(string memory newBaseURI) public onlyRole(ADMIN_ROLE) {
        baseURI = newBaseURI;
    }

    /// @notice Function to get get URI for a given token ID
    /// @param tokenId The token ID for which to update the URI
    /// @return The URI for the given token ID
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token ID does not exist");
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /// @notice Override of the safeTransferFrom function to include admin check. This overrides both SafeTransferFrom functions.
    /// @dev Adds onlyRole check to restrict transfers to admins
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override(ERC721Upgradeable, IERC721) onlyRole(ADMIN_ROLE) {
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    /// @notice Override of the transferFrom function to include admin check
    /// @dev Adds onlyRole check to restrict transfers to admins
    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721Upgradeable, IERC721) onlyRole(ADMIN_ROLE) {
        super.transferFrom(from, to, tokenId);
    }

    /// @notice Transfers ownership of the contract and administrative roles to a new account.
    /// @dev This will transfer the `DEFAULT_ADMIN_ROLE` and the `ADMIN_ROLE` to the new owner.
    function transferOwnership(address newOwner) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newOwner != address(0), "New owner cannot be the zero address");

        // Transfer the DEFAULT_ADMIN_ROLE to the new owner
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, newOwner);

        // Transfer the ADMIN_ROLE to the new owner
        _revokeRole(ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, newOwner);

        // Update the owner state variable to the new owner
        owner = newOwner;

        // Emit an event for the ownership transfer
        emit OwnershipTransferred(msg.sender, newOwner);
    }
}