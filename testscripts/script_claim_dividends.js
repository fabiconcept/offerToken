module.exports = async function(callback) {
    try {
        OffrToken = artifacts.require("OffrToken");
        let accounts = await web3.eth.getAccounts();
        OffrToken = await OffrToken.deployed();
        
        //Transaction 1
        console.log(await OffrToken.withdrawAmount({from: accounts[0]}));

        //Transaction 2
        console.log(await OffrToken.withdrawAmount({from: accounts[1]}));
    
        //Transaction 3
        console.log(await OffrToken.withdrawAmount({from: accounts[2]}));

        //Transaction 4
        console.log(await OffrToken.withdrawAmount({from: accounts[3]}));

        callback();

} catch(e){
 console.log(e)
}
}
