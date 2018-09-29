const Web3 = require('web3');
const utils = require('ethereumjs-util');
var HDWalletProvider = require("truffle-hdwallet-provider");
const rlp = utils.rlp;

var abi = [
	{
		"constant": false,
		"inputs": [
			{
				"name": "_serializedBlockHeader",
				"type": "bytes"
			}
		],
		"name": "addBlock",
		"outputs": [],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "function"
	},
	{
		"constant": true,
		"inputs": [],
		"name": "startingBlock",
		"outputs": [
			{
				"name": "",
				"type": "uint256"
			}
		],
		"payable": false,
		"stateMutability": "view",
		"type": "function"
	},
	{
		"constant": true,
		"inputs": [
			{
				"name": "",
				"type": "uint256"
			}
		],
		"name": "blocks",
		"outputs": [
			{
				"name": "storageRoot",
				"type": "bytes32"
			},
			{
				"name": "blockhash",
				"type": "bytes32"
			},
			{
				"name": "timestamp",
				"type": "uint256"
			}
		],
		"payable": false,
		"stateMutability": "view",
		"type": "function"
	},
	{
		"inputs": [],
		"payable": false,
		"stateMutability": "nonpayable",
		"type": "constructor"
	}
];
var mnemonic="display powder calm absorb flush mandate beach cable price stairs play diet evil arrive pet";
var provider = new HDWalletProvider(mnemonic, 'https://ropsten.infura.io/ht4yyh0j0UUoTa2p9nF2', 0, 1, false);
console.log("Public key = " + provider.addresses[0]);
var web3 = new Web3(provider);

var done = {};
var smallestNotChecked = 0;

var contract = web3.eth.contract(abi).at("0x829bd87d2bcc2f95bc6f63a9dff18fad07fcaa84");


	var addPrefix=function(hex){
		if(hex.length%2==0){
			return "0x"+hex;
		}
		else{
			return "0x0"+hex;
		}
	};
	var buildCallBack = function(num){
		return function(err,res){
					if(res!=null){
						data = [];
						data.push(res.parentHash);
						data.push(res.sha3Uncles);
						data.push(res.miner);
						data.push(res.stateRoot);
						data.push(res.transactionsRoot);
						data.push(res.receiptsRoot);
						data.push(res.logsBloom);
						data.push(addPrefix(parseInt(res.difficulty).toString(16)));
						data.push(addPrefix(res.number.toString(16)));
						data.push(addPrefix(res.gasLimit.toString(16)));
						data.push(addPrefix(res.gasUsed.toString(16)));
						data.push(addPrefix(res.timestamp.toString(16)));
						data.push(res.extraData);
						data.push(res.mixHash);
						data.push(res.nonce);
						if(res.hash==="0x"+utils.keccak256(rlp.encode(data)).toString("hex")==false){
							done[res.number]="done";
							console.log("Hashes of "+res.number+" Matches = ",res.hash==="0x"+utils.keccak256(rlp.encode(data)).toString("hex"),res.hash,"0x"+utils.keccak256(rlp.encode(data)).toString("hex"));
					///		console.log(data);
						}
						else{
							var paramToSend = "0x"+rlp.encode(data).toString("hex");
							if(res.number==null){
									
								done[num]=undefined;
								console.log("Strange Block ",res);
								console.log(" ",paramToSend);
							
							}
							if(done[num]!=="done" && done[num]!=="processing"){
								contract.blocks.call(num,function(err,res){
									if(res!=null && res!=undefined && res[0]==='0x0000000000000000000000000000000000000000000000000000000000000000'){
										contract.addBlock(paramToSend,{
											from:provider.addresses[0],
											gas:"300000"
										},function(err,res){
											console.log("addBlock",err,res);
											if(err===null){
												done[res.number]="done";
											}
										});
									}
									else{
										if(res!=null && res!=undefined && res[0]!='0x0000000000000000000000000000000000000000000000000000000000000000'){
											done[res.number]="done";
											console.log(num," Exists")
										}
										else{
											done[num]=undefined;
										}
									}
								});
							}
						}
						
					}
					else{
						done[num]=undefined;
					}
				}
	}
	
contract.startingBlock.call(function(err,res){
	smallestNotChecked = parseInt(res);
	
	setInterval(function(){
		
		
		web3.eth.getBlockNumber(function(err,res){
	//		console.log("Last block ",res," smallestNotChecked ",smallestNotChecked);
			if(smallestNotChecked===0){
				smallestNotChecked = parseInt(res);
			}
			if(res==null){
				console.log("No Block ",arguments);
			}
			for(var i=smallestNotChecked;i<=res;i++){
				if(done[i]===undefined){
					done[i]="processing";
				//	console.log("Processing ",i);
					web3.eth.getBlock(i,buildCallBack(i));
				}else{
					if(done[i]==="done"){
						done[i]="notified";
						console.log("Done["+i+"]");
						smallestNotChecked=smallestNotChecked+1;
					}
				}
			}
		})
	},1000);
});
