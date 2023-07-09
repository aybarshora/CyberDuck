// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CyberDuckCoin is
    Context,
    IERC20,
    IERC20Metadata,
    ReentrancyGuard,
    Ownable
{
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    address private _uniswapV2Pair;
    address private _stakingContract;
    address private _marketingAddress;

    event SentToStaking(uint256 amount);
    event SentToMarketing(uint256 amount);
    event SetStaking(address newStaking);
    event SetMarketing(address newMarketing);

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _mint(_msgSender(), 400000000000000 * 10 ** decimals());
    }

    function uniswapV2Pair() public view returns (address) {
        return _uniswapV2Pair;
    }

    function stakingContract() public view returns (address) {
        return _stakingContract;
    }

    function marketingAddress() public view returns (address) {
        return _marketingAddress;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override nonReentrant returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override nonReentrant returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override nonReentrant returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance.sub(amount));

        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual nonReentrant returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual nonReentrant returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(_msgSender(), spender, currentAllowance.sub(subtractedValue));
        return true;
    }

    function _burn(address account, uint256 amount) private {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0));
        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _mint(address account, uint256 amount) private {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account);
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }

    function _beforeTokenTransfer(address from, address to) private view {
        if (_uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "Trading is not started");
        }
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient);
        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );

        if (_uniswapV2Pair == sender || _uniswapV2Pair == recipient) {
            uint256 amountToStaking = amount.mul(7).div(1000); // 0.7% = 7 / 1000
            uint256 amountToMarketing = amount.mul(5).div(1000); // 0.5% = 5 / 1000
            amount = amount.sub(amountToStaking).sub(amountToMarketing);

            _balances[_stakingContract] = _balances[_stakingContract].add(
                amountToStaking
            );
            _balances[_marketingAddress] = _balances[_marketingAddress].add(
                amountToMarketing
            );

            emit SentToStaking(amountToStaking);
            emit SentToMarketing(amountToMarketing);
        }

        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }

    function burn(uint256 value) external nonReentrant {
        _burn(_msgSender(), value);
    }

    function setUni(address newUniswapV2Pair) external onlyOwner {
        require(newUniswapV2Pair != address(0), "Invalid Uniswap pair address");
        _uniswapV2Pair = newUniswapV2Pair;
    }

    function setStakingContract(address newStakingContract) external onlyOwner {
        require(
            newStakingContract != address(0),
            "Invalid staking contract address"
        );
        _stakingContract = newStakingContract;
        emit SetStaking(newStakingContract);
    }

    function setMarketingAddress(
        address newMarketingAddress
    ) external onlyOwner {
        require(newMarketingAddress != address(0), "Invalid marketing address");
        _marketingAddress = newMarketingAddress;
        emit SetMarketing(newMarketingAddress);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) private {}
}
