const bs58 = require('bs58');
const fs = require('fs');
const fetch = require('node-fetch');
const solanaWeb3 = require('@solana/web3.js');
const { Keypair } = solanaWeb3;
const { randomUUID } = require('crypto');

function generateRandomUserAgent() {
  const userAgents = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Safari/605.1.15',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0',
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:89.0) Gecko/20100101 Firefox/89.0',
    'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:88.0) Gecko/20100101 Firefox/88.0',
    'Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.1 Mobile/15E148 Safari/604.1',
    'Mozilla/5.0 (Linux; Android 11; SM-G960U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
  ];
  return userAgents[Math.floor(Math.random() * userAgents.length)];
}

function generateRandomDelay(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

async function send(address) {
  const userAgent = generateRandomUserAgent();
  const delay = generateRandomDelay(1000, 5000); // Delay antara 1-5 detik

  await new Promise((resolve) => setTimeout(resolve, delay));

  const response = await fetch('https://api.tally.so/forms/wdvkJK/respond', {
    method: 'POST',
    headers: {
      'Host': 'api.tally.so',
      'User-Agent': userAgent,
      'Accept': 'application/json, text/plain, */*',
      'Accept-Language': 'id,en-US;q=0.7,en;q=0.3',
      'Accept-Encoding': 'gzip, deflate, br',
      'Referer': 'https://tally.so/',
      'Content-Type': 'application/json',
      'Tally-Version': '2025-01-15',
      'Content-Length': '257',
      'Origin': 'https://tally.so',
      'Sec-Fetch-Dest': 'empty',
      'Sec-Fetch-Mode': 'cors',
      'Sec-Fetch-Site': 'same-site',
      'Priority': 'u=0',
      'Te': 'trailers',
    },
    body: JSON.stringify({
      sessionUuid: randomUUID(),
      respondentUuid: randomUUID(),
      responses: {
        '4c4c2153-a44e-49c2-987a-0061413d975a': address,
      },
      captchas: {},
      isCompleted: true,
      password: '',
    }),
  });

  return response.json();
}

(async () => {
  const read2 = fs.readFileSync(`pk.txt`, 'UTF-8');
  const list2 = read2.split(/\r?\n/);
  for (var i = 0; i < list2.length; i++) {
    var secretKeyBase58 = list2[i].split('|')[0];
    const secretKeyBytes = bs58.decode(secretKeyBase58);
    const keypair = Keypair.fromSecretKey(secretKeyBytes);
    console.log();
    console.log(` [${i + 1}/${list2.length}] Public Address:`, keypair.publicKey.toBase58());
    const confirmAddress = await send(keypair.publicKey.toBase58());
    console.log(confirmAddress);
  }
})();