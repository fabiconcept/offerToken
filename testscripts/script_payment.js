module.exports = async function(callback) {
    try {
        ERC20 = artifacts.require("ERC20");
        const usdcContract = new web3.eth.Contract(ERC20.abi, "0xaD6D458402F60fD3Bd25163575031ACDce07538D");

        OffrToken = artifacts.require("OffrToken");
        let accounts = await web3.eth.getAccounts();
        OffrToken = await OffrToken.deployed();
        
        //amount of the lease payment
        var usdcAmount = 1;
        var usdcTokens = web3.utils.toWei(usdcAmount.toString(), 'ether');
        var bnAmount = web3.utils.toBN(usdcTokens);
        
        
        //get stable coin USDC balance of the user account 
        console.log(await usdcContract.methods.balanceOf(accounts[0]).call({from: accounts[0]}));
        
        //approve the Token Smart Contract to send amount of stable coin USDC from user account
        console.log(await usdcContract.methods.approve(OffrToken.address, bnAmount).send({from: accounts[0]}));

        //get the Token Smart Contract is allowed to send amount of stable coin USDC from user account
        console.log(await usdcContract.methods.allowance(accounts[0], OffrToken.address).call({from: accounts[0]}));

        //send stable coin USDC from user account to the contract 
        console.log(await OffrToken.receivePayment(bnAmount, {from: accounts[0]}));

        callback();

    } catch(e){
        console.log(e)
    }
}
