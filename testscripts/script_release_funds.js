module.exports = async function(callback) {
    try {
        OffrToken = artifacts.require("OffrToken");
        OffrToken = await OffrToken.deployed();
        
        //Release the funds to the registered beneficiary address
        console.log(await OffrToken.releaseFunds());

        callback();

} catch(e){
 console.log(e)
}
}
