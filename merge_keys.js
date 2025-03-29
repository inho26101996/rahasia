const fs = require('fs');

try {
  const seedPhrases = fs.readFileSync('seed_phrase.txt', 'UTF-8').split(/\r?\n/);
  const privateKeys = [];

  for (const seedPhrase of seedPhrases) {
    const trimmedSeedPhrase = seedPhrase.trim();
    if (trimmedSeedPhrase) {
      const inputFilename = trimmedSeedPhrase.replace(/ /g, '_') + '.txt';
      try {
        const privateKey = fs.readFileSync(inputFilename, 'UTF-8').trim();
        privateKeys.push(privateKey);
      } catch (error) {
        console.error(`Gagal membaca file ${inputFilename}: ${error.message}`);
      }
    }
  }

  fs.writeFileSync('pk.txt', privateKeys.join('\n'));
  console.log('Semua kunci privat berhasil digabungkan ke pk.txt');
} catch (error) {
  console.error(`Terjadi kesalahan: ${error.message}`);
}