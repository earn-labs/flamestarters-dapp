import fs from "fs";
import process from "process";
import { readdir } from "fs/promises";

let legendaryTraits = new Map<string, string>([
  ["164.png", "Pokémon"],
  ["75.png", "Bruce Lee"],
  ["50.png", "Rambo"],
  ["143.png", "Neo"],
  ["133.png", "Ironman"],
  ["30.png", "Anonymous"],
  ["169.png", "Jason Voorhees"],
]);

const url = "ipfs://bafybeihmnzln7owlnyo7s6cjtca66d35s3bl522yfx5tjnn3j7z6ol4aiy/";

interface metaData {
  name: string;
  description: string;
  image: string;
  attributes: any[];
}

function shuffle(array: string[]) {
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    const temp = array[i];
    array[i] = array[j];
    array[j] = temp;
  }
  return array;
}

async function getFileList(dirName: string) {
  let files: string[] = [];
  const items = await readdir(dirName, { withFileTypes: true });

  for (const item of items) {
    if (item.isDirectory()) {
      files = [...files, ...(await getFileList(`${dirName}/${item.name}`))];
    } else {
      files.push(`${dirName}/${item.name}`);
    }
  }

  return files;
}

async function readDir(dirName: string) {
  let files: string[] = [];
  const fileList = await getFileList(dirName);
  for (let index = 0; index < fileList.length; index++) {
    const file = fileList[index];
    const relPath = file.replace(dirName + "/", "");
    files.push(relPath);
  }
  return files;
}

async function main() {
  const metadataFile = fs.readFileSync("TheFlameStartersTraits.txt", "utf-8");

  const metadataList = metadataFile.split(/\r?\n/).slice(0, 177);
  const randomizedList = shuffle(metadataList);

  // write logs
  fs.writeFile("./logs.txt", "", function (err) {});

  for (let index = 1; index <= 177; index++) {
    const line = randomizedList[index - 1];
    console.log(index + ": " + line);
    const [imgFile, rarity, design, accessory, special] = line.split("\t");

    // write logs
    fs.appendFileSync("./logs.txt", index + ": " + imgFile + "\n");

    // write metadata file
    let json: metaData;
    json = {
      name: "FlameStarter #" + index,
      description: "",
      image: url + rarity + "/" + imgFile,
      attributes: [
        {
          trait_type: "Rarity",
          value: rarity,
        },
        {
          trait_type: "Design",
          value: design,
        },
        {
          trait_type: "Accessory",
          value: accessory,
        },
        {
          trait_type: "Special",
          value: special,
        },
      ],
    };

    fs.writeFileSync("./metadata/" + (index - 1), JSON.stringify(json));
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
