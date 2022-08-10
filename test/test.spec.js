const SubWalletFactory = artifacts.require('./SubWalletFactory.sol');

contract('SubWalletFactory', accounts => {
   it('테스트 1 은 테스트 1이다', () => {
       return SubWalletFactory.deployed('0x')
           .then(instance => { // instance 말 그대로 객체
               // instance.clone();

               // logic

               return false // result value
           })
   });
});