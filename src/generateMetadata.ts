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
  const imageList = await readDir("images");

  // write logs
  fs.writeFile("./logs.txt", "", function (err) {});

  for (let index = 1; index <= imageList.length; index++) {
    const file = imageList[index - 1];
    console.log(file);
    const [trait, name] = file.split("/");

    let legTrait = legendaryTraits.get(name);
    if (legTrait == undefined) {
      legTrait = "";
    }

    // write logs
    fs.appendFileSync("./logs.txt", index + ": " + file + "\n");

    // write metadata file
    let json: metaData;
    json = {
      name: "FlameStarter #" + index,
      description: "",
      image: url + trait + "/" + name,
      attributes: [
        {
          trait_type: "Rarity",
          value: trait,
        },
        {
          trait_type: "Legendary",
          value: legTrait,
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
