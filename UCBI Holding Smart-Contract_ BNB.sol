// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract UCBIHolding {

    string public name = "UCBI Holding";
    string public symbol = "UCBI";
    uint8 public decimals = 8;

    uint256 public totalSupply;
    uint256 public constant MAX_SUPPLY = 20_000_000 * 10 ** 8;

    address public owner;

    bool public locked = true;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => bool) public allowedAddresses;
    mapping(address => bool) public lockedAddresses;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        totalSupply = MAX_SUPPLY;
        balanceOf[msg.sender] = MAX_SUPPLY;
        allowedAddresses[msg.sender] = true;
    }

    // ------------------------
    // Ownership
    // ------------------------

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }

    // ------------------------
    // Lock system
    // ------------------------

    function allowAddress(address _addr, bool _allowed) external onlyOwner {
        require(_addr != owner, "Owner restricted");
        allowedAddresses[_addr] = _allowed;
    }

    function lockAddress(address _addr, bool _locked) external onlyOwner {
        require(_addr != owner, "Owner restricted");
        lockedAddresses[_addr] = _locked;
    }

    function setLocked(bool _locked) external onlyOwner {
        locked = _locked;
    }

    function canTransfer(address _addr) public view returns (bool) {
        if (locked) {
            if (!allowedAddresses[_addr] && _addr != owner) return false;
        } else {
            if (lockedAddresses[_addr]) return false;
        }
        return true;
    }

    // ------------------------
    // ERC20 core
    // ------------------------

    function transfer(address to, uint256 amount) external returns (bool) {
        require(to != address(0), "Zero address");
        require(canTransfer(msg.sender), "Transfer locked");
        require(balanceOf[msg.sender] >= amount, "Balance low");

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(to != address(0), "Zero address");
        require(canTransfer(from), "Transfer locked");
        require(balanceOf[from] >= amount, "Balance low");
        require(allowance[from][msg.sender] >= amount, "Allowance low");

        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;

        emit Transfer(from, to, amount);
        return true;
    }

    // ------------------------
    // Burn
    // ------------------------

    function burn(uint256 amount) external {
        require(balanceOf[msg.sender] >= amount, "Balance low");

        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;

        emit Transfer(msg.sender, address(0), amount);
    }
}