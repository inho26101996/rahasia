const bs58 = require('bs58');
const fs = require('fs');
const fetch = require("node-fetch");
const chalk = require("chalk");
const solanaWeb3 = require('@solana/web3.js');
const {
    Keypair,
    PublicKey,
} = solanaWeb3
const { randomUUID } = require('crypto');

// Konfigurasi
const TALLY_FORM_URL = 'https://api.tally.so/forms/wdvkJK/respond';
const DELAY_MS = 1500; // Jeda antar permintaan (ms)

async function sendToTally(address) {
    try {
        const response = await fetch(TALLY_FORM_URL, {
            method: 'POST',
            headers: {
                'Host': 'api.tally.so',
                'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:136.0) Gecko/20100101 Firefox/136.0',
                'Accept': 'application/json, text/plain, */*',
                'Accept-Language': 'id,en-US;q=0.7,en;q=0.3',
                'Accept-Encoding': 'gzip, deflate, br',
                'Referer': 'https://tally.so/',
                'Content-Type': 'application/json',
                'Tally-Version': '2025-01-15',
                'Origin': 'https://tally.so',
                'Sec-Fetch-Dest': 'empty',
                'Sec-Fetch-Mode': 'cors',
                'Sec-Fetch-Site': 'same-site',
                'Priority': 'u=0',
                'Te': 'trailers'
            },
            body: JSON.stringify({
                'sessionUuid': randomUUID(),
                'respondentUuid': randomUUID(),
                'responses': {
                    '4c4c2153-a44e-49c2-987a-0061413d975a': address
                },
                'captchas': {},
                'isCompleted': true,
                'password': ''
            })
        });

        if (!response.ok) {
            const errorText = await response.text();
            console.error(chalk.red(`Error sending to Tally.so for ${address}: ${response.status} - ${errorText}`));
            return { error: true, status: response.status, message: errorText };
        }

        const data = await response.json();
        return data;

    } catch (error) {
        console.error(chalk.red(`Fetch error for ${address}:`), error);
        return { error: true, message: error.message };
    }
}

(async () => {
    try {
        const pkFile = 'pk.txt';
        const fileContent = fs.readFileSync(pkFile, 'UTF-8');
        const privateKeys = fileContent.trim().split(/\r?\n/).map(line => line.split('|')[0]);

        const totalKeys = privateKeys.length;
        console.log(chalk.green(`Processing ${totalKeys} private keys from ${pkFile}`));

        for (let i = 0; i < totalKeys; i++) {
            const secretKeyBase58 = privateKeys[i];

            try {
                const secretKeyBytes = bs58.decode(secretKeyBase58);
                const keypair = Keypair.fromSecretKey(secretKeyBytes);
                const publicKeyBase58 = keypair.publicKey.toBase58();

                console.log();
                console.log(chalk.cyan(`? [${i + 1}/${totalKeys}] Public Address:`), publicKeyBase58);

                const tallyResponse = await sendToTally(publicKeyBase58);
                console.log(tallyResponse);

                if (tallyResponse && tallyResponse.submissionId) {
                    console.log(chalk.green(`  > Successfully sent address to Tally.so`));
                } else if (tallyResponse && tallyResponse.error) {
                    console.log(chalk.yellow(`  > Problem sending to Tally.so:`), tallyResponse.message);
                } else {
                    console.log(chalk.yellow(`  > Unknown response from Tally.so:`), tallyResponse);
                }

                if (i < totalKeys - 1) {
                    await new Promise(resolve => setTimeout(resolve, DELAY_MS));
                }

            } catch (error) {
                console.error(chalk.red(`Error processing private key ${secretKeyBase58}:`), error);
            }
        }

        console.log(chalk.green('\nFinished processing all private keys.'));

    } catch (error) {
        console.error(chalk.red('Error reading or processing pk.txt:'), error);
    }
})();

function unix(rarityLocked) {
    var date = new Date(rarityLocked)
    let year = date.getFullYear();
    let month = date.getMonth() + 1;
    let day = date.getDate();
    let hour = date.getHours();
    let minute = date.getMinutes();
    let second = date.getSeconds();
    return ({
        day,
        month,
        year,
        hour,
        minute,
        second
    });
}
