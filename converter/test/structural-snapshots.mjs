import crypto from "node:crypto";
import fs from "node:fs/promises";
import path from "node:path";
import assert from "node:assert/strict";
import { convertProgram } from "../src/api.mjs";
import { repositoryRoot } from "./repository.mjs";

const examples = path.join(repositoryRoot, "scaffold", "examples");

// Hashes cover the plain-data scaffold IR rather than generated source text.
// They keep the semantic shape of every fixture reviewable and deterministic.
const expected = {
  "001": "a4fc4a7d5d7f5c8092562202ce314b6b3337f9c322da42d3b7284eeba01739fa",
  "002": "a57a9f6729fd23e9a8e6dc277bf56d1c0593676c787a8de04e67872f8291e460",
  "003": "f8983569633b8e8c3f1b1977139501b1ec6c0e0182d86461b50e939633190444",
  "004": "3e09fb1fe88cf1ec1cc074bfc1f3bf88d0470a72fe1af208667a8ee26c2c1a7b",
  "005": "133e7af3b06ed3104511e599e0f0d1582a9c4fc19bee52ffefa5776212882ab3",
  "006": "f2132c5fccfed1942ec70bb7cca80f2395929164460630ad6c0e14865ec11ce4",
  "007": "156aaa3322c3e64a3a04072b308e69f7d8da7ea2a322510530e66f4b18468c33",
  "008": "200f00da9d513bad194502821afe05952b60befad3832ce009c9525c4d4f1f0c",
  "009": "ce0dfe222f8491aba5596ef079482d77dd2f4e26bcfa8156ed54b5eacb4db938",
  "010": "93e050fccd00ebe3293149210490bf5b34703b92ac7e66226084d16508fb98df",
  "011": "f73cd1dc627cbb282263810214c26ccb61b8dbb568bb1985ab9fc721e45c0942",
  "012": "20935dfbaad502e632d28abb83ab4d05e850f03dba92ed3f64a0b4c918c9b2d0",
  "013": "9d9ad2511b33caf36f97d15c17f5b8221894d1f31cee143268f5bbdf5bc99abf",
  "014": "22c50224a1944205f654a384ad1e68f80c25ab8c62e6f8a3cea03cb06ba5fb32",
  "015": "ef9699af26eed23d4bf9bff987e77bd3c9d41632c2414d5eba457c8715d2c1cc",
  "016": "dd661149014ee357f00fc1a30d41e1c5563b404933761acab0d335a56676e337",
  "017": "aebe901960c8ccf8a1e0b17e68378c75377f424cd86b343dac8f0624fbedb998",
  "018": "f444f90fc6b9969c083dbbf0179e7b06f3a0560c2fd0973a86a7eb66fe452c1c",
  "019": "8e3e35968a4a63b235d1a989e8bec7e4c7ee432027af05f924a16648df353514",
  "020": "4705ba6a0b843d005b8a6fad00c2790472ab2f3bc0145364afa54902538a96d9",
  "021": "3948937d61723786d1c6a1ca1da96d673a364d1ffbe4cb656d89237006bf577a",
  "022": "4ed7e94b26fea1bba7df7334e8be11d85e65ae909e565681fe609d2075b3c128",
  "023": "f7627e9505090fb2cfa9312cb148725f635a9ce224e01fa61b0208081dfd2196",
  "024": "b98d28d286dd5ae60ed596d7d1c7fd889f4296a206b8eb9abfbbbb1fb0b72514",
  "025": "b886943ea7fd2db66aaebbfa428965b5aab3367828d73ae389e287168807cd62",
  "026": "d1b63c278df07eb9a1592295e83f266afc0fcd131a4a4649b21747410a2850fe",
  "027": "9130f730f2559ea77c4880ffed9c83e009e6f6a1475bf3b4f9fc7bdb63fcb94c",
  "028": "69114dae329340980956bcc64f4832d05c50fe24437058424ea2aae0cf79151b",
  "029": "63884f276e66fc3fbb6776d316a051b4fd20392c6d549c8cfa5018d8167c3211",
  "030": "07a4a8621fd8ff21eba3d9672abedabe4e641860692077c88eddfabc0f26fa78",
  "031": "99ad4adee1684bf4722dd0901e242238d19536cc33c68dfba06177ed75d44035",
  "032": "fc0b15e26f9011b5865ca25064c95e2ad7ba4231d816534bfca9a267797f9d05",
  "033": "804f61b185d66e78b0a74fa949b8e3cf082d46c7b99cf114a93685c50dcdf532",
  "034": "a15a06776268b7e0c5740ac6dfd581e8577bfa50f6a793a4d23d4b92f71e74ea",
  "035": "71e142caa590aa9549dfef6cc7717fa6ed2b7f0766bcdf7a20c518009f919ebc",
  "036": "59ffae31319c794e5dcb2376fee3906da04b138c74e7b7c40c7e35df6ad43dd2",
  "037": "02785e197f5f572f79c4afb676859db4d6d56ada64025f087c9e47f77bf4a435",
  "038": "74c64cc7f42f255ee0cee03a1b5201cc30ad66de5436090454dbc03e17dea0b3",
  "039": "807a2c3b058c77a02b96498af47114d8a07979ed2d0ee44ac32b3703cb0db757",
  "040": "29aab7d2b6c3d09f6efc0b5cbd9f151054b9c7364435113716e6d8347a123675",
  "041": "14801b5346b987fd6568862df8008ff3d063e769cbb79e4c020bf7995f6355ae",
  "042": "f217b88790948a17769cbd19810d001ebae29efd332d6e5d3adaee7e051fd98d",
  "043": "7cf722998b89c63c2445115b65d60ab58062499905d676ef33da0efca58e49c5",
  "044": "53fd6af1a2fb11d9fe0f8079a3e0bce7093621cf77a9b96fba91a819dbe21500",
  "045": "75fcc0471d3edb486ad7be35a04ed0dc27f5a7a79a35fa21b8e2f4210e4f31d9",
  "046": "1b7421997a8b31e085431e5474cd7da1d200135b98d14de98535719bbd6bb9a4",
  "047": "335de65513732e2a0e2255704ddf5fd209cc43b5c8b986ae6c6e84c6c1fd9047",
  "048": "5e01e04324743a5b020c562215a043d118c8ba37668252fd0db56abbf8557ffe",
  "049": "5b3e3e589dca869ee58fe795683290fba504deea01a30dadea46c10818b7ffcc",
  "050": "d1628151fe1d79ae2bb093f4990631ae9ec6d5d827bd42e177fe2caca03bd655",
  "051": "f18a8664342f0fcba60e17e9176b849000bfded8514776b61633f2bbcd3d7ae2",
  "052": "97c17a79e55242f2dd76209f7315fb8d673927af26cf684561d0488b53252109",
  "053": "e25be6a7d70d153bba2781f4f5d083420fc74feb8b1b5b3795e5c994d57d30aa",
  "054": "740f1b849b11544144ece1f495246b080c9d707528b9996058038105411cbd88",
  "055": "138784c7a90470fac1a996a69abad98b99c6086abcf1dc5916d60815b558e3d2",
  "056": "5874c75e865b3e2921a8f1cccb2cf2dd7963e347f1d5608a20d88a518b23d1d0",
  "057": "fcc542ae4f6eadd23b026b6d7d2304373ff4f1fca9f7c2834662fbeb85416be4",
  "058": "f4fd986b145050ba6fb1dc8b20e0b3ce24fd07a90695e46812c97cdf06321be3",
};

function snapshot(result, example) {
  return {
    example,
    supported: result.supported,
    kind: result.reportIR?.programKind,
    diag: result.diagnostics.filter((item) => item.severity !== "info").map((item) => item.code),
    interfaces: result.scaffoldIR?.interfaces ?? [],
    members: result.scaffoldIR?.members?.map((item) => item.name ?? item.source) ?? [],
    methods: result.scaffoldIR?.methods?.map((item) => ({ name: item.name, ops: item.operations?.map((operation) => operation.kind) ?? [] })) ?? [],
    screen: result.scaffoldIR?.screenBuilder?.operations?.map((operation) => operation.kind) ?? [],
    list: result.scaffoldIR?.listProcessing?.handlers?.map((item) => item.name) ?? [],
    session: result.scaffoldIR?.sessionOperations?.map((operation) => operation.kind) ?? [],
    continuations: result.scaffoldIR?.continuations?.map((item) => ({ id: item.id, live: item.liveVariables ?? [] })) ?? [],
    cfg: result.scaffoldIR?.controlFlowGraphs?.map((item) => item.name) ?? [],
  };
}

for (let number = 1; number <= 58; number++) {
  const example = String(number).padStart(3, "0");
  const filename = `zgg_ex_${example}.prog.abap`;
  const source = await fs.readFile(path.join(examples, filename), "utf8");
  const result = await convertProgram({ source, filename, className: `ZCL_SNAP_${example}`, transactionCode: `ZSN${example}`, mode: "partial" });
  const hash = crypto.createHash("sha256").update(JSON.stringify(snapshot(result, example))).digest("hex");
  assert.equal(hash, expected[example], `structural snapshot changed for example ${example}`);
}

console.log(`structural snapshots passed for ${Object.keys(expected).length} fixtures`);
