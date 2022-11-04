const voting = artifacts.require('voting.sol');

contract('voting',(accounts)=>{
    before(async()=>{
        instance = await voting.deployed();

    })

    it('ensures that the balance is 100', async()=>{
        let balance = await instance.viewBalance();
        assert.equal(balance,0,"The initial balance should be 0")
    })

})