// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts//access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./math/SafeMathInt.sol";
import "./math/SafeMathUint.sol";
import "./uniswap/IUniswapV2Router02.sol";


/// @title Offr Token implementation - Distributing Security Token for a one-time fundraising 
/// @author Fabiconcept (Fabian Ajokubi T.)
/// @notice You can use this security token implementation to raise one-time funds and distribute USDC to token holders on a regular basis
/// @dev Value is stored as USDC. The implementation has not been audited.

contract OffrToken is Context, AccessControl, IERC20 {
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 public _uniswapRouter;
    address public _usdcToken = 0xaD6D458402F60fD3Bd25163575031ACDce07538D;
    IERC20 public _usdcInstance;

    address payable public owner;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 public _rate;
    uint256 public _cap;
    address public _beneficiary;
    bool fundingReleased = false;

    uint256 constant private magnitude = 2**128;
    uint private claimableAmountPerToken;
    mapping(address => int256) private claimableAmountCorrections;
    mapping(address => uint256) private withdrawnAmounts;

    /// @notice Token purchase event
    /// @param transmitter address of the initiator
    /// @param buyer address of the buyer
    /// @param amountUSDC amount of USDC for the token purchase
    /// @param amountToken amount of purchased tokens
    event TokensPurchased(address indexed transmitter, address indexed buyer, uint256 amountUSDC, uint256 amountToken);

    /// @notice Release of raised funds event
    /// @param beneficiary adress of the beneficiary
    /// @param amountUSDC amount of the released USDC
    event FundsReleased(address indexed beneficiary, uint256 amountUSDC);

    /// @notice received payment from beneficiary event
    /// @param project_owner address of the beneficiary
    /// @param amountUSDC amount of the received USDC 
    event PaymentReceived(address indexed project_owner, uint256 amountUSDC);
    
    /// @notice pays a percentage of dividend (1.25)
    /// @notice received payment from beneficiary event
    /// @param project_owner address of the beneficiary
    /// @param amountUSDC amount of the received USDC 
    event PaymentReceivedPart(address indexed project_owner, uint256 amountUSDC);

    /// @notice payment to the investor event
    /// @param tokenholder address of the investor / tokenholder
    /// @param amountUSDC amount of the paid out USDC
    event AmountPaidOut(address indexed tokenholder, uint256 amountUSDC);

    /// @notice Initialization of the Security Token (OffrToken)
    /// @param name_ Name (OffrToken)
    /// @param symbol_ Symbol (OFFR)
    /// @param decimals_ Decimals (18)
    /// @param cap_ Fund raising cap (1_000_000_000)
    /// @param rate_ Conversion Rate USDC <-> Security Token ( 1 <-> 1)
    /// @param beneficiary_ Address of the beneficiary
    constructor (string memory name_, string memory symbol_, uint8 decimals_, uint256 cap_, uint256 rate_, address beneficiary_) {
        _setupRole(MINTER_ROLE, _msgSender());
        _uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _usdcInstance = IERC20(_usdcToken);
        require(rate_ > 0, "rate is 0");
        require(cap_ > 0, "cap is 0");
        require(beneficiary_ != address(0), "address is null");
        _cap = cap_;
        _rate = rate_;
        _beneficiary = beneficiary_;

        owner = payable(msg.sender); 
    }

    /// @notice Only owner modifer
    /// restricts access to specific functions on the contract
    modifier onlyOwner {
        require(msg.sender == owner, "Only the Owner can call this function");
        _;
    }

    /// @notice Function to destroy this Contract
    /// @param onlyOwner can execute
    function destroy() public onlyOwner{
        selfdestruct(owner);
    }

 
    /// @notice Returns the name
    /// @return The Name
    function name() public view returns (string memory) {
        return _name;
    }
    
    /// @notice Returns the Owner address
    /// @return The owner
    function owner() public view returns (address memory) {
        return owner;
    }

    /// @notice Returns the symbol
    /// @return The symbol
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /// @notice Returns the decimals
    /// @return The decimals
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /// @notice Returns funding cap
    /// @return The cap
    function cap() public view returns (uint256) {
        return _cap;
    }

    /// @notice Returns the rate
    /// @return The rate
    function rate() public view returns (uint256) {
        return _rate;
    }

    /// @notice Returns if the fundrasing is still open
    /// @return boolean fundraising open
    function tokensale_open() public view returns (bool) {
        return _cap > totalSupply();
    }

    /// @notice Returns the total token supply
    /// @return amount of supplied token
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /// @notice Returns the balance of a specific address
    /// @param account address of the account 
    /// @return amount of tokens hold by an address
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /// @notice Transfers `amount` of tokens to a `recipient`
    /// @param recipient adddress of the recipient
    /// @param amount amount of the tokens to transfer
    /// @return boolean transfer was sucessfull
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /// @notice Returns the remaining number of tokens that spender will be allowed to spend on behalf of owner through transferFrom. This is zero by default.
    /// @param owner address of the account which owns the tokens
    /// @param spender address of the account that is allowed to spend the tokens
    /// @return amount of spendable tokens
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /// @notice Sets `amount` as the allowance of spender over the callers tokens
    /// @param spender address of the spender account
    /// @param amount amount to allow for spender to send
    /// @return boolean indicating whether the operation succeeded
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    /// @notice Moves amount tokens from sender to recipient using the allowance mechanism. amount is then deducted from the caller???s allowance.
    /// @param sender address of the account which owns the tokens
    /// @param recipient address of the account which owns the tokens
    /// @param amount amount of tokens to send
    /// @return boolean indicating whether the operation succeeded
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "transfer amount exceeds allowance"));
        return true;
    }


    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "transfer from the zero address");
        require(recipient != address(0), "transfer to the zero address");

        _beforeTokenTransfer(sender, amount);

        _balances[sender] = _balances[sender].sub(amount, "transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        //curate the claimable amount of sender and recipient
        int256 correction = claimableAmountPerToken.mul(amount).toInt256Safe();
        claimableAmountCorrections[sender] = claimableAmountCorrections[sender].add(correction);
        claimableAmountCorrections[recipient] = claimableAmountCorrections[recipient].sub(correction);
    }

    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "mint to the zero address");

        _beforeTokenTransfer(address(0), amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /// @notice Sets amount as the allowance of spender over the caller's token
    /// @param owner amount of USDC that will be invested
    /// @dev if the transaction will be send with ETH, then the tokenbuy will be performed by exchanging these ETH to the given USDC amount
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "approve from the zero address");
        require(spender != address(0), "approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /// @notice Function for investors to buy tokens with ETH or USDC
    /// @param usdcAmount_ amount of USDC that will be invested
    /// @dev if the transaction will be send with ETH, then the tokenbuy will be performed by exchanging these ETH to the given USDC amount
    function buyTokens(uint256 usdcAmount_) public payable {
        if (msg.value > 0) {
            convertEthToUsdc(usdcAmount_); 
        } else {
            require(_usdcInstance.transferFrom(msg.sender, address(this), usdcAmount_));
        }
        uint256 tokens = usdcAmount_.mul(_rate);
        _mint(msg.sender, tokens);
        emit TokensPurchased(_msgSender(), msg.sender, usdcAmount_, tokens);
    }


    /// @notice Functions that converts ETH to USDC
    /// @param usdcAmount amount of USDC that will be purchased
    function convertEthToUsdc(uint usdcAmount) public payable {
        uint deadline = block.timestamp + 15;
        address[] memory path = new address[](2);
        path[0] = _uniswapRouter.WETH();
        path[1] = _usdcToken;

        (uint[] memory amts) = _uniswapRouter.swapETHForExactTokens{ value: msg.value }(usdcAmount, path, address(this), deadline);    
        require(amts[0] > 0, "Exchange failed.");
        // refund leftover ETH to user
        (bool success,) = msg.sender.call{ value: address(this).balance }("");
        require(success, "refund failed");
    }
  

    /// @notice Functions that receives left-over ETH from uniswap exchanges
  receive() payable external {} 

    /// @notice Minting function for registered distributors
    /// @param buyer address of the token buyer
    /// @param amount amount of tokens to be minted
    function sendTokens(address buyer, uint256 amount) public {
        require(buyer != address(0), "buyer is a zero address");
        require(amount != 0, "weiAmount is 0");
        
        uint256 tokens = amount.mul(_rate);

        mint(buyer, tokens);
        emit TokensPurchased(_msgSender(), buyer, amount, tokens);
    }

    /// @notice Function that checks if the minting is performed from a minter account
    /// @param to receiving account of the minting
    /// @param amount amount of tokens to be minted
    function mint(address to, uint256 amount) internal {
        require(hasRole(MINTER_ROLE, _msgSender()), "must have minter role to mint");
        _mint(to, amount);
    }


    /// @notice Function that checks conditions (will the cap be exceeded after minting new tokens?) before token transfer
    /// @param from account that initiated a sending transaction
    /// @param amount amount of tokens to be transferred
    function _beforeTokenTransfer(address from, uint256 amount) internal virtual {
        if (from == address(0)) { // When minting tokens, check the sale cap
            require(totalSupply().add(amount) <= _cap, "cap exceeded");
        }
    }

    /// @notice Function to release the funding to the beneficiary
    function releaseFunds() public onlyOwner {
        require(tokensale_open() == false, "funds not raised");
        require(fundingReleased == false, "funding already released");
        require(_usdcInstance.transfer(_beneficiary, _cap.mul(_rate)), "sending USDC failed");
        emit FundsReleased(_beneficiary, _cap);
        fundingReleased = true;
    }

    /// @notice Function that receives payments from beneficiary and distribute them to the tokenholders
    /// @param usdcAmount amount that the beneficiary will pay 
    function receivePayment(uint256 usdcAmount) public onlyOwner {
        require(totalSupply() > 0, "total supply");
        require(_usdcInstance.transferFrom(msg.sender, address(this), usdcAmount), "USDC Transfer not possible");
        claimableAmountPerToken = claimableAmountPerToken.add((usdcAmount).mul(magnitude) / totalSupply());
        emit PaymentReceived(msg.sender, usdcAmount);
    }
    
    function receivePaymentPart(uint256 usdcAmount) public onlyOwner {
        require(totalSupply() > 0, "total supply");
        require(_usdcInstance.transferFrom(msg.sender, address(this), usdcAmount), "USDC Transfer not possible");
        claimableAmountPerToken = claimableAmountPerToken.add(((usdcAmount).mul(magnitude) / totalSupply() * 0.0125));
        emit PaymentReceivedPart(msg.sender, usdcAmount);
    }
    

    /// @notice Function to claim the claimable funds
    function withdrawAmount() public {
        uint256 _claimableAmount = claimableAmountOf(msg.sender);
        if (_claimableAmount > 0) {
            withdrawnAmounts[msg.sender] = withdrawnAmounts[msg.sender].add(_claimableAmount);
            require(_usdcInstance.transfer(msg.sender, _claimableAmount), "transfer not successful");
            emit AmountPaidOut(msg.sender, _claimableAmount);
        }
    }

    /// @notice Returns the total amount of funds that are claimable for a specified account
    /// @param _owner address of the account
    /// @return total amount of funds that are claimable
    function claimableAmountOf(address _owner) public view returns(uint256) {
        return accumulativeAmountOf(_owner).sub(withdrawnAmounts[_owner]);
    }

    /// @notice Returns the total amount of funds that have been withdrawn for a specified account
    /// @param _owner address of the account
    /// @return total amount of funds that have been withdrawn
    function withdrawnAmountOf(address _owner) public view returns(uint256) {
        return withdrawnAmounts[_owner];
    }

    /// @notice Returns the total amount of funds that were claimable for a specified account
    /// @param _owner address of the account
    /// @return total amount of funds that were claimable
    function accumulativeAmountOf(address _owner) public view returns(uint256) {
        return claimableAmountPerToken.mul(balanceOf(_owner)).toInt256Safe()
        .add(claimableAmountCorrections[_owner]).toUint256Safe() / magnitude;
    }

}
