pragma solidity ^0.4.25;

contract Blockchain{
    struct Block{
        address author;
        uint32 height; 
        uint8 status;
        bytes32 prevBlockHash;
        bytes32 nextBlockHash;
        bytes32 rootDataHash;
        uint256 nonce;
        
    }
    
    
    struct WithdrawAttempt{
        address user;
        uint64 value;
        uint64 blockNumberOfAttempt;
        bytes32 blockHashToTest;
        uint8 status;
    }
    struct DepositAttempt{
        address user;
        uint64 value;
        uint8 status;
    }
    
    uint256 public targetDifficulty=1000;
    uint8 constant STATUS_PENDING = 0;
    uint8 constant STATUS_REJECTED = 1;
    uint8 constant STATUS_DONE = 2;
    uint256 constant TARGET_TIME = 300;
    uint256 constant MIN_DEPOSITS_COUNT = 10;
    uint256 constant CHALLENGE_TIME_BLOCKS = 300;
    uint256 constant DEPOSIT_REMOVAL_ALLOWENCE_TIME = 20;
    uint256 constant BLOCK_MINING_BOND = 100 finney;
    uint256 constant MINIMUM_FEE = 1 finney;
    uint256 constant WITHDRAW_BOND = 100 finney;
    uint256 public lastTime; 
    uint256 public lastDepositDone;
    uint256 public maxCurrentHeight;
    bytes32 public highestHash;
    
    event NewBlock(bytes32 blockHash, string ipfsHash);
    event NewTopBlock(bytes32 blockHash, string ipfsHash);
    
    mapping(bytes32 => Block ) public blocks;
    WithdrawAttempt[] public pendingWithdraw;
    DepositAttempt[] public pendingDeposit;
    
    function computeDifficulty(address sender,bytes32 lastHash , bytes32 rootDataHash,uint256 nonce, string ipfsHash) public pure returns(uint256) {
        bytes32 blockHash = keccak256(sender,rootDataHash,nonce,ipfsHash);
        uint256 diff = uint256(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)/ uint256(keccak256(lastHash,blockHash));
        return diff;
    }
    
    function addBlock(string ipfsHash,bytes32 lastHash,bytes32 rootDataHash,uint256 nonce,uint256 _lastDepositDone) public payable {
        require(msg.value==BLOCK_MINING_BOND);
        require(blocks[lastHash].height>0 || lastHash==bytes32(0),'incorrect parent');
        require(_lastDepositDone == pendingDeposit.length || _lastDepositDone > lastDepositDone+MIN_DEPOSITS_COUNT,'too few deposits made');
        bytes32 blockHash = keccak256(msg.sender,rootDataHash,nonce,ipfsHash);
        uint256 diff = uint256(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)/ uint256(keccak256(lastHash,blockHash));
        require(diff>targetDifficulty,'to easy, more difficulty required');
        blocks[blockHash]=Block(msg.sender,blocks[lastHash].height+1,uint8(0),lastHash,0,rootDataHash,nonce);
        
        emit NewBlock(blockHash,ipfsHash);
        if(maxCurrentHeight<blocks[lastHash].height+1){
            maxCurrentHeight = blocks[lastHash].height+1;
            highestHash = blockHash;
            emit NewTopBlock(blockHash,ipfsHash);
        }
        for(uint256 i=lastDepositDone;i<_lastDepositDone;i++){
            if(pendingDeposit[i].status==STATUS_PENDING){
                pendingDeposit[i].status = STATUS_DONE;
            }
        }
        lastDepositDone = _lastDepositDone;
        if((now-lastTime)>TARGET_TIME*110/100){
            targetDifficulty = targetDifficulty*90/100;
        }
        else{
            if(now-lastTime<TARGET_TIME*90/100){
                targetDifficulty = targetDifficulty*100/90;
            }
        }
    }
    
    function challenge(uint256 blockNumber,uint256 challengeType,bytes data) public payable{
        /* TODO  for every type one SC being this type resolver*/ 
    }
    
    function deposit(uint256 value) public payable{
        require(msg.value-MINIMUM_FEE>=value);
        /* TODO */
    }
    
    function withdrawBlockDeposit(bytes32 hash) public{
        if(blocks[hash].height>0 && blocks[hash].height<maxCurrentHeight-CHALLENGE_TIME_BLOCKS){
            if(blocks[hash].status!=STATUS_DONE){
                blocks[hash].status=STATUS_DONE;
                blocks[hash].author.transfer(BLOCK_MINING_BOND);
            }
        }
    }
    
    function reverseBlock(bytes32 hash) public{
        //TODO:
        //author can reverse its own block and get deposit back if following conditions are met
        //1. block is not part of current cannonical chain (it is not on a path down from highestHash) 
        //2. block has property nextBlockHash set to 0
        //3. maxCurrentHeight is bigger than block height by CHALLENGE_TIME_BLOCKS or more
    }
    
    
    
    function withdrawAll(bytes32 blockHash,uint256 nonce, address account, uint64 value,bytes32[] merkleProof) public {
        bytes32 rootHash = blocks[blockHash].rootDataHash; 
        bytes32 accHash = keccak256(nonce, account, value);
        for(uint256 i=0;i<merkleProof.length;i++){
            if(uint256(accHash)<uint256(merkleProof[i])){
                accHash = keccak256(accHash,merkleProof[i]);
            }else{
                accHash = keccak256(merkleProof[i],accHash);
            }
        }
        require(accHash==rootHash,'incorrect merkleProof');
        pendingWithdraw.push(WithdrawAttempt(msg.sender,value,uint64(block.number),blockHash,STATUS_PENDING));
    }
    
    function executeWithdraw(uint256 withdrawIndex) public{
        require(block.number>pendingWithdraw[withdrawIndex].blockNumberOfAttempt+CHALLENGE_TIME_BLOCKS);
        require(pendingWithdraw[withdrawIndex].status==STATUS_PENDING);
        pendingWithdraw[withdrawIndex].status = STATUS_DONE;
        pendingWithdraw[withdrawIndex].user.transfer(pendingWithdraw[withdrawIndex].value*(10**6));
    }
    
}
