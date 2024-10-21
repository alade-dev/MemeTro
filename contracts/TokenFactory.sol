// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./Erc20.sol";

/// @title TokenFactory - A factory contract for creating ERC20 tokens with metadata
/// @notice This contract allows users to create their own ERC20 tokens by paying a fee.
/// @dev The contract uses Ownable for access control and supports metadata storage for each created token.
contract TokenFactory is Ownable, ReentrancyGuard {
    /// @notice Fee for creating a token
    uint256 public fee = 0.1 ether;
    
    /// @notice Array that stores addresses of created tokens
    address[] public tokens;

    /// @dev Struct to store metadata for each token
    /// @param name The name of the token
    /// @param symbol The symbol of the token
    /// @param description A description of the token
    /// @param createdBy The creator's name or identifier
    /// @param image A URL or link to an image representing the token
    /// @param createdAt Timestamp of when the token was created
    struct TokenMetadata {
        string name;
        string symbol;
        string description;
        string createdBy;
        string image;
        uint256 createdAt;
    }

    /// @notice Mapping of token address to its metadata
    mapping(address => TokenMetadata) public tokenMetadata;

    /// @notice Event emitted when a new token is created
    /// @param tokenAddress The address of the newly created ERC20 token
    /// @param name The name of the token
    /// @param symbol The symbol of the token
    /// @param description A description of the token
    /// @param createdBy The creator's name or identifier
    /// @param image A URL or link to an image representing the token
    /// @param createdAt The timestamp when the token was created
    event TokenCreated(address indexed tokenAddress, string name, string symbol, string description, string createdBy, string image, uint256 createdAt);

    /// @notice Event emitted when the fee is updated
    /// @param amount The new fee amount
    event FeeUpdated(uint256 amount);

    /// @notice Event emitted when fees are withdrawn
    /// @param to The address that received the withdrawn fees
    /// @param amount The amount of fees withdrawn
    event FeesWithdrawn(address indexed to, uint256 amount);

    /// @dev Modifier to ensure the correct fee is paid
    modifier validFee() {
        require(msg.value == fee, "Invalid fee amount");
        _;
    }

    /// @notice Constructor that sets the initial owner of the contract
    /// @param initialOwner The address of the initial owner
    constructor(address initialOwner) Ownable(initialOwner) {}

    /// @notice Creates a new ERC20 token and stores its metadata
    /// @dev Requires the sender to pay the creation fee
    /// @param name The name of the token
    /// @param symbol The symbol of the token
    /// @param maxSupply The maximum supply of the token
    /// @param description A description of the token
    /// @param createdBy The creator's name or identifier
    /// @param image A URL or link to an image representing the token
    function createToken(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        string memory description,
        string memory createdBy,
        string memory image
    ) external payable validFee() {

        require(bytes(name).length > 0, "Token name cannot be empty");
        require(bytes(symbol).length > 0, "Token symbol cannot be empty");

        ERC20 newToken = new ERC20(name, symbol, maxSupply, msg.sender);
        address tokenAddress = address(newToken);
        tokens.push(tokenAddress);

        tokenMetadata[tokenAddress] = TokenMetadata({
            name: name,
            symbol: symbol,
            description: description,
            createdBy: createdBy,
            image: image,
            createdAt: block.timestamp
        });

        newToken.transferOwnership(msg.sender);

        emit TokenCreated(tokenAddress, name, symbol, description, createdBy, image, block.timestamp);
    }

    /// @notice Returns the list of all created token addresses
    /// @return An array of addresses representing the created tokens
    function getTokens() external view returns (address[] memory) {
        return tokens;
    }

    /// @notice Retrieves the metadata of a token
    /// @param tokenAddress The address of the token whose metadata is being fetched
    /// @return A TokenMetadata struct containing the token's metadata
    function getTokenMetadata(address tokenAddress) external view returns (TokenMetadata memory) {
        require(tokenAddress != address(0), "Invalid token address");
        require(tokenExists(tokenAddress), "Token does not exist");
        return tokenMetadata[tokenAddress];
    }

    /// @notice Checks if a token address exists in the tokens array
    /// @param tokenAddress The address of the token to check
    /// @return A boolean indicating if the token exists
    function tokenExists(address tokenAddress) internal view returns (bool) {
        for (uint i = 0; i < tokens.length; i++) {
            if (tokens[i] == tokenAddress) {
                return true;
            }
        }
        return false;
    }

    /// @notice Updates the fee for creating a token
    /// @dev Only callable by the contract owner
    /// @param newFee The new fee amount in wei
    function setFees(uint256 newFee) external onlyOwner {
        require(newFee > 0, "Fee must be greater than zero");
        fee = newFee;
        emit FeeUpdated(newFee);
    }

    /// @notice Withdraws all collected fees to a specified address
    /// @dev Only callable by the contract owner
    /// @param to The address to which the fees will be withdrawn
    function withdrawFees(address payable to) external onlyOwner nonReentrant {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No fees to withdraw");

        (bool sent, ) = to.call{value: contractBalance}("");
        require(sent, "Failed to withdraw fees");

        emit FeesWithdrawn(to, contractBalance);
    }
}
