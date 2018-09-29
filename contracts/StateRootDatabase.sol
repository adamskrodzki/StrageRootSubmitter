pragma solidity ^0.4.24;
contract StateRootDatabase  {
    
    event BlockAdded(uint256 _blockNumber);
    struct Block{
        bytes32 storageRoot;
        bytes32 blockhash;
        uint256 timestamp;
    }
    
    mapping(uint256 => Block) public blocks;
    uint256 public startingBlock;
    
    constructor() public{
        startingBlock = block.number;
        
    }
    
    
    function addBlock(bytes _serializedBlockHeader)public {
        uint256 newOffset = moveOffset(_serializedBlockHeader,0,4);
        bytes32 storageRoot = decodeBytes32(_serializedBlockHeader,newOffset);
        bytes32 blkHash = keccak256(_serializedBlockHeader);
        newOffset = moveOffset(_serializedBlockHeader,newOffset,5); 
        uint256 blockNum =  decodeUint256(_serializedBlockHeader,newOffset);
        newOffset = moveOffset(_serializedBlockHeader,newOffset,3); 
        uint256 timestamp =  decodeUint256(_serializedBlockHeader,newOffset);
        require(blocks[blockNum].timestamp==0);
        require(block.blockhash(blockNum)==blkHash);
        blocks[blockNum] = Block(storageRoot,blkHash,timestamp);
        emit BlockAdded(blockNum);
    }
    
    function decodeBytes32(bytes _data,uint256 _offset) pure private  returns(bytes32){
        uint256 retVal ;
        uint256 firstByte = uint256(_data[_offset]);
        if(firstByte<0x80){
            return bytes32(firstByte);
        }
        uint256 length = firstByte-0x80;
        for(uint256 i=0;i<length;i++){
            retVal=retVal*256+uint256(_data[_offset+1+i]);
        }
        return bytes32(retVal);
    }
    
    function decodeUint256(bytes _data,uint256 _offset) pure private returns(uint256){
        
        uint256 retVal ;
        uint256 firstByte = uint256(_data[_offset]);
        if(firstByte<0x80){
            return firstByte;
        }
        uint256 length = firstByte-0x80;
        for(uint256 i=0;i<length;i++){
            retVal=retVal*256+uint256(_data[_offset+1+i]);
        }
        return retVal;
    }
    
    
    function moveOffset(bytes _data,uint256 initialOffset,uint256 shift) view private returns (uint256){
        uint256 firstByte = uint256(_data[initialOffset]);
        uint256 length =0;
        uint256 lenOfLength =0;
        uint256 i =0;
        if(shift==0){
            return initialOffset;
        }
        if(firstByte<0x80){
            return moveOffset(_data,initialOffset+1,shift-1);
        }
        if(firstByte<0xb8){
            length = firstByte - 0x80;
            return moveOffset(_data,initialOffset+1+length,shift-1);
        }
        if(firstByte<0xc0){
            lenOfLength = firstByte - 0xb7;
            for(i=0;i<lenOfLength;i++){
                length = length*256+uint256(_data[initialOffset+i+1]);
            }
            return moveOffset(_data,initialOffset+1+length+lenOfLength,shift-1);
        }
        if(firstByte<0xf8){
            uint256 elementCount = firstByte - 0xc0;
            initialOffset = initialOffset+1;
            for(i=0;i<elementCount;i++){
                initialOffset = moveOffset(_data,initialOffset,1);
            }
            return moveOffset(_data,initialOffset+1,shift-1);
        }
        if(firstByte>0xf7){
            lenOfLength = firstByte - 0xf7;
            return moveOffset(_data,initialOffset+1+lenOfLength,shift-1);
        }
    }
}
