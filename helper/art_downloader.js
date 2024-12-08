const fs = require('fs');
const https = require('https');
const readline = require('readline');
const path = require('path');
const { execSync } = require('child_process');

// Check if Puppeteer is installed, and install it if not
try {
    require.resolve('puppeteer');
} catch (e) {
    console.log("Puppeteer not found. Installing...");
    try {
        execSync('npm install puppeteer', { stdio: 'inherit' });
        console.log("Puppeteer installed successfully.");
    } catch (installError) {
        console.error("Failed to install Puppeteer. Ensure you have npm installed and try again.");
        process.exit(1);
    }
}

const puppeteer = require('puppeteer'); // Import Puppeteer after ensuring it's installed

(async () => {
    // Get the game ID from the command-line arguments
    const gameId = process.argv[2];

    if (!gameId) {
        console.error("Usage: node script.js <gameid>");
        process.exit(1); // Exit if no game ID is provided
    }

    const csvFilePath = './helper/ArtDB.csv';
    const outputDir = './icons/art/tmp';

    // Ensure the output directory exists
    if (!fs.existsSync(outputDir)) {
        fs.mkdirSync(outputDir, { recursive: true });
    }

    // Function to search the CSV file for the game ID
    const findUrlForGameId = async (gameId) => {
        const fileStream = fs.createReadStream(csvFilePath);
        const rl = readline.createInterface({
            input: fileStream,
            crlfDelay: Infinity,
        });

        for await (const line of rl) {
            const [id, urlPart] = line.split('|');
            if (id === gameId) {
                return `https://www.ign.com/games/${urlPart}`; // Construct the full URL
            }
        }

        return null; // Return null if no match is found
    };

    const url = await findUrlForGameId(gameId);

    if (!url) {
        console.error(`Game ID "${gameId}" not found in ArtDB.csv`);
        process.exit(1);
    }

    const browser = await puppeteer.launch();
    const page = await browser.newPage();

    try {
        console.log(`Navigating to: ${url}`);
        await page.goto(url, { waitUntil: 'networkidle2' });

        // Find the first image with src starting with 'https://assets-prd.ignimgs.com'
        const imgUrl = await page.evaluate(() => {
            const img = document.querySelector('img[src^="https://assets-prd.ignimgs.com"]'); // Look for images with this src prefix

            if (img) {
                return img.src.split('?')[0]; // Remove query parameters
            }
            return null;
        });

        if (imgUrl) {
            // Get the file extension from the URL
            const fileExtension = path.extname(imgUrl).split('?')[0]; // Ensures query strings don't interfere

            // Save the image in the specified directory with the correct file extension
            const fileName = path.join(outputDir, `${gameId}${fileExtension}`);
            console.log(`Downloading image from: ${imgUrl}`);
            console.log(`Saving as: ${fileName}`);
            const file = fs.createWriteStream(fileName);
            https.get(imgUrl, (response) => response.pipe(file));
        } else {
            console.log("No image found with the specified source.");
        }
    } catch (error) {
        console.error(`Failed to fetch the page: ${error.message}`);
    }

    await browser.close();
})();
