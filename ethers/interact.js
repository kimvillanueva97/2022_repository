import {Contract, getDefaultProvider} from 'ethers';

const nowlyCollectionAddress = '0xF32C7E8a5548326044826Cf2c0C8E5A54FF63FBA';
const isRevealedABI = [
  {
    'inputs': [
      {
        'internalType': 'uint256',
        'name': 'tokenId',
        'type': 'uint256',
      },
    ],
    'name': 'isRevealed',
    'outputs': [
      {
        'internalType': 'bool',
        'name': '',
        'type': 'bool',
      },
    ],
    'stateMutability': 'view',
    'type': 'function',
    'constant': true,
  },
];

const interact = async () => {
  const provider =
    getDefaultProvider('https://nd-213-305-711.p2pify.com/a52ecfbd315f6b51e25d14b5f7080481');

  const contract =
    new Contract(nowlyCollectionAddress, isRevealedABI, provider);

  const isRevealed = await contract.isRevealed(2);

  console.log(isRevealed);
};

interact();
