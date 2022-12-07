const OffrToken = artifacts.require("OffrToken");

module.exports = function(deployer, network, accounts) {
  
  //Token name
  var tokenName = "OffrToken";
  //Token label
  var tokenLabel = "OFFR";
  //Funding size
  var fundingAmount = 100;
  var fundingAmountInWei = web3.utils.toWei(fundingAmount.toString(), 'ether');
  var BNfundingAmountInWei = web3.utils.toBN(fundingAmountInWei);
  
  //Conversion rate USD to OffrToken - 1 means 1 USD is equal 1 OFFR
  var conversionRateTokenUSD = 1;

  //Beneficiary address
  var beneficiary = accounts[3];

  //Deploy Smart Contract
  deployer.deploy(OffrToken, tokenName, tokenLabel, decimals, BNfundingAmountInWei, conversionRateTokenUSD, beneficiary);
  //constructor (string memory name_, string memory symbol_, uint8 decimals_, uint256 cap_, uint256 rate_, address beneficiary_) {
};
