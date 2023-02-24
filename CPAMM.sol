// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

//CPMM : Constat product market maker
//This contract implemets CPMM for fix pair of 2 ERC20 Tokens
//Does not account for fees

contract CPMM{

    //variable of token instance to track the two tokens
    //imutable because they will be intitalized once in constructor when deploye
    IERC20 public immutable token0;
    IERC20 public immutable token1;

    //to keep track of token reseve inside pool/pair
    uint public reserve0;
    uint public reserve1;

    //variables to track native LP tokens
    uint private _totalSupply;
    mapping(address => uint) private _balances;

    //constructor to declare to token with the addresses supplied
    constructor(address _token0, address _token1){
        
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);

    }

    //Mint function to mint LP tokens
    function _mint(uint _amount,address _to) private {

        _totalSupply += _amount;
        _balances[_to] += _amount;

    }
    //Burn fucntion to burn LP tokens
    function _burn(uint _amount,address _to) private {

        _totalSupply -= _amount;
        _balances[_to] -= _amount;
        
    }

    //Add liquidity function
    function addLiquidity(uint _amount0, uint _amount1) external returns(uint _mintAmount){
        
        require( _amount0 > 0 || _amount1 > 0 );

        token0.transferFrom(msg.sender,address(this),_amount0);
        token1.transferFrom(msg.sender,address(this),_amount1);

        update();
        
        if(_totalSupply==0){

            require( _amount0 > 0 && _amount1 > 0 , " intial supply : both token needed");

                _mintAmount = sqrt(_amount0*_amount1);

        }
        else{

            _mintAmount = minimum(_amount0*_totalSupply/reserve0,_amount1*_totalSupply/reserve1);

            _mint(_mintAmount,msg.sender);

        }

        require(_mintAmount>0, "LP token:0");

    }

    //remove liquidity function
    function removeLiquidity(uint _burnAmount) external {

        require(_burnAmount >= _balances[msg.sender], " not enough LP token to burn");

        uint _amount0;
        uint _amount1;

        _amount0 = _burnAmount*reserve0/_totalSupply;
        _amount1 = _burnAmount*reserve1/_totalSupply;

        _burn(_burnAmount,msg.sender);

        token0.transferFrom(address(this),msg.sender,_amount0);
        token1.transferFrom(address(this),msg.sender,_amount1);

        update();
        
    }

    //swap function to let user exchange the tokens
    function swap(address _tokenIn,uint _amountIn) external returns(uint _amountOut){
        
        require( _tokenIn == address(token0) || _tokenIn == address(token1),"Invalid Token");

        require(_amountIn>0 ,"Amount must be greater than zero");

        uint K = reserve0*reserve1;

        (uint reserveIn,uint reserveOut) = _tokenIn == address(token0) ? (reserve0,reserve1) : (reserve1,reserve0);
        
        (IERC20 tokenIn,IERC20 tokenOut) = _tokenIn == address(token0) ? (token0,token1) : (token1,token0);
 
        _amountOut = _amountIn*reserveOut / (reserveIn + _amountIn);

        tokenIn.transferFrom(msg.sender,address(this),_amountIn);
        tokenOut.transferFrom(address(this),msg.sender,_amountOut);

        update();

        uint newK = reserve0*reserve1;

        require(newK>K,"CPMM : K error");

    }

    //update function to keep track of reserves
    function update() private {

        reserve0 = token0.balanceOf(address(this));
        reserve1 = token0.balanceOf(address(this));

    }

    //supporting fucntions returns minimum of the two
    function minimum(uint x, uint y) private pure returns(uint min){

        min = x < y ? x : y;

    }

    //sqrt function
    function sqrt(uint y) private pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);
}