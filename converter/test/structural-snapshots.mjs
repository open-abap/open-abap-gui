import crypto from "node:crypto";
import fs from "node:fs/promises";
import path from "node:path";
import assert from "node:assert/strict";
import { convertProgram } from "../src/api.mjs";
import { repositoryRoot } from "./repository.mjs";

const examples = path.join(repositoryRoot, "examples");

// Hashes cover the plain-data scaffold IR rather than generated source text.
// They keep the semantic shape of every fixture reviewable and deterministic.
const expected = {
  "001": "de3882f1a305a5c909cdd1aa651f1377cd7c677b6509c7e15592f966032eee6c",
  "002": "987eb915d45eca90f3e843424a241aed05ec3b246f70931696dd1be009e0a2de",
  "003": "da9a60b344160dcbefe15b2830383bcdc927b5a56571a9ef1cc6e86053e29a5c",
  "004": "6b2a05b6223151a9431c93d96d959254ec8840c69d5d1f444e76c8eb3b90da18",
  "005": "856de21b40bf5fd826712469fcd20b80548dd51443709dcfcbacd39a6e248a41",
  "006": "80df8182cd79f2e38150d42124f77eb55d8af4758775c5610abe2288c453218a",
  "007": "156aaa3322c3e64a3a04072b308e69f7d8da7ea2a322510530e66f4b18468c33",
  "008": "200f00da9d513bad194502821afe05952b60befad3832ce009c9525c4d4f1f0c",
  "009": "ce0dfe222f8491aba5596ef079482d77dd2f4e26bcfa8156ed54b5eacb4db938",
  "010": "93e050fccd00ebe3293149210490bf5b34703b92ac7e66226084d16508fb98df",
  "011": "af72712fcc27526bdbc8886e7446525f7bb029753319a84ac40b0a89fb98858a",
  "012": "75effe6b5b4ca6abbe54190c747e5ea2e7fb8bd06635bcd74178a9df1f26166d",
  "013": "df39f19f642b5d825e1a009d95d1be430b8d61dfd8e053ea1cf1ddde84b15f22",
  "014": "0018a3cd94e609bf98ce440397b8f76b8f84006bf90f5fcdd7df20febbb305f9",
  "015": "f9b5c7ba04e16a11bff2c80be950910ebd74e536c4791019ddb91eaed7d79b5a",
  "016": "1bdc0f0a3408132af8e30d56e18475c124ad38a9d5bdb32e9231f3dfd73bc880",
  "017": "bad0f24effd1463a458f375e829ecc56aeb79d718ff81d04f14693b22edcf234",
  "018": "f444f90fc6b9969c083dbbf0179e7b06f3a0560c2fd0973a86a7eb66fe452c1c",
  "019": "8e3e35968a4a63b235d1a989e8bec7e4c7ee432027af05f924a16648df353514",
  "020": "66df72f80b3f2883ca11fd228a3c806f6a48ed7ef6a237574d0850a50a93eeff",
  "021": "3948937d61723786d1c6a1ca1da96d673a364d1ffbe4cb656d89237006bf577a",
  "022": "4ed7e94b26fea1bba7df7334e8be11d85e65ae909e565681fe609d2075b3c128",
  "023": "f7627e9505090fb2cfa9312cb148725f635a9ce224e01fa61b0208081dfd2196",
  "024": "b98d28d286dd5ae60ed596d7d1c7fd889f4296a206b8eb9abfbbbb1fb0b72514",
  "025": "6ddcddac728989a954f468c516d38e25683e6c24bb52239e1a7710b6d9515858",
  "026": "7244d5e994b4a2923bbdaf76afcb32a75a201c1ce6c0ec96b65a286fa9a9a290",
  "027": "91939411aa1ad6fee70b8fb965c27d9c1c96ace51edf53aed4237d63d3d83ea1",
  "028": "69114dae329340980956bcc64f4832d05c50fe24437058424ea2aae0cf79151b",
  "029": "63884f276e66fc3fbb6776d316a051b4fd20392c6d549c8cfa5018d8167c3211",
  "030": "07a4a8621fd8ff21eba3d9672abedabe4e641860692077c88eddfabc0f26fa78",
  "031": "99ad4adee1684bf4722dd0901e242238d19536cc33c68dfba06177ed75d44035",
  "032": "543bea8a789a381782a0d9101d93b92f30f428bb70f23a962c5c0ba06524aa78",
  "033": "804f61b185d66e78b0a74fa949b8e3cf082d46c7b99cf114a93685c50dcdf532",
  "034": "a15a06776268b7e0c5740ac6dfd581e8577bfa50f6a793a4d23d4b92f71e74ea",
  "035": "71e142caa590aa9549dfef6cc7717fa6ed2b7f0766bcdf7a20c518009f919ebc",
  "036": "a0ed639fe48311f76dff10813bce71bd48a7993f737b4db4bc22ba749bc5ed78",
  "037": "02785e197f5f572f79c4afb676859db4d6d56ada64025f087c9e47f77bf4a435",
  "038": "74c64cc7f42f255ee0cee03a1b5201cc30ad66de5436090454dbc03e17dea0b3",
  "039": "807a2c3b058c77a02b96498af47114d8a07979ed2d0ee44ac32b3703cb0db757",
  "040": "29aab7d2b6c3d09f6efc0b5cbd9f151054b9c7364435113716e6d8347a123675",
  "041": "aba072a29029f6f31e869e2d4bcca36dfb4fa2b16f32d96b4afe679921a32d3d",
  "042": "f217b88790948a17769cbd19810d001ebae29efd332d6e5d3adaee7e051fd98d",
  "043": "7cf722998b89c63c2445115b65d60ab58062499905d676ef33da0efca58e49c5",
  "044": "53fd6af1a2fb11d9fe0f8079a3e0bce7093621cf77a9b96fba91a819dbe21500",
  "045": "75fcc0471d3edb486ad7be35a04ed0dc27f5a7a79a35fa21b8e2f4210e4f31d9",
  "046": "1b7421997a8b31e085431e5474cd7da1d200135b98d14de98535719bbd6bb9a4",
  "047": "335de65513732e2a0e2255704ddf5fd209cc43b5c8b986ae6c6e84c6c1fd9047",
  "048": "5e01e04324743a5b020c562215a043d118c8ba37668252fd0db56abbf8557ffe",
  "049": "5b3e3e589dca869ee58fe795683290fba504deea01a30dadea46c10818b7ffcc",
  "050": "01731355465707de14af055c1a2d9f97a9830866c7520cf9f9888dafab3603fb",
  "051": "75b24e512b769b0904bbb05efbbed73c7e968b51f1df32e1fb046f63d29e4271",
  "052": "46b3bbe5a0af965b825c74e12306d9982a4d2ba97a06e7a3ea15d4b0c7020108",
  "053": "00f15de51ab9494a4e95dac6e67593c5c1daa6faaae2cb31ce1f9d97d5bdd07e",
  "054": "0c9c14b367c365dbc78c5082a36392d38c9f0afc9a7a2eac2623788abb6766bf",
  "055": "138784c7a90470fac1a996a69abad98b99c6086abcf1dc5916d60815b558e3d2",
  "056": "c4f0e9f49501100325f52c5ca2313c026a9ba94f46f2630cf1ed6d8463d241ce",
  "057": "fcc542ae4f6eadd23b026b6d7d2304373ff4f1fca9f7c2834662fbeb85416be4",
  "058": "b9a08011e72a2b5218d9aa165958fbe757368e2fff502db17b65d263ca037aa4",
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
