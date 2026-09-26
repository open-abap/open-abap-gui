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
  "012": "7209d3eaf1ac5a700c58cb7623335ecf02a0463a3bf06945d85d86661b03eb60",
  "013": "df39f19f642b5d825e1a009d95d1be430b8d61dfd8e053ea1cf1ddde84b15f22",
  "014": "0018a3cd94e609bf98ce440397b8f76b8f84006bf90f5fcdd7df20febbb305f9",
  "015": "4a8f513092698b65ff5d44c2b64e5b664b5e2d956770fae5edfb2de9645844fb",
  "016": "0c0f2ef275614a26ae21485d3b5c396bea30556c1286ec84328452711afabd50",
  "017": "1b1cfa310d21d4b03db11dc51daa14a5342782d655c83643cabf11da2f7b59b1",
  "018": "8632f29db4357fd44e60817dc8c93cf94d1f65abb7afc403abeeb7464e52a4a6",
  "019": "5efbd301077b2f1c53c71c29b9b8cde444667c933ab335347a6c0d1c43e6539c",
  "020": "8e6719c90e1a91bacaaddc3cd70a43457c254b61fbc59cf5a960f8ba37a0a540",
  "021": "3a83baa6d63e32859bf1314da4a328bff47411052b586f93be840a05cc79a94a",
  "022": "c2b1313227884f80f67822f4c444525b7e446c00d72d8ea9e50320f6110f0975",
  "023": "6ab9fdcdde3d7b260f0648c869eee723f3a3778cdf0914cf05171f2ab6bb65a2",
  "024": "b98d28d286dd5ae60ed596d7d1c7fd889f4296a206b8eb9abfbbbb1fb0b72514",
  "025": "6ddcddac728989a954f468c516d38e25683e6c24bb52239e1a7710b6d9515858",
  "026": "7244d5e994b4a2923bbdaf76afcb32a75a201c1ce6c0ec96b65a286fa9a9a290",
  "027": "631e95670f446184ba208d2e894d5fdeaad64e1f76f68a6a45ed003e42abe360",
  "028": "160b1a6a54dac3bacd0ec28fbe6835a1be10c30101498a85acddc15e2207275f",
  "029": "8dcb24f3ec9b03e1f7aa9de0d17d53e085e4e64910e6fc9fd25904f49e60865c",
  "030": "41629d6b0ca29c0dce406f4e84dc4bc85cdde4248664798cb7079bc8093fe22f",
  "031": "f841b7fe7b78d8f8adac4b558bfc7cbc58f63c49f5e50c42d19ecfde0730a408",
  "032": "85666add3bd3d430e2fa630c709d98f0b47f64c14057053d9616f9e2e5cba5b2",
  "033": "62a8cbff460ab15b4372a5bc4ce512abc109527599a11bd0c3ba417b817ff4c5",
  "034": "43eec9a9eee02f9e7635cf3c011f97ef4c13aff91cdebd8ed1b4f87b5247cf17",
  "035": "13714ec690cbe9b94634fa0934d45d88475e9cce37d151b90860016b20c86513",
  "036": "80a1606c1c89ee9b2102dfe566a899e5216fed363ed62b56b74d31382f2fd562",
  "037": "ea13fd61dc9cd0dea71d22b8eab82069939fba6e2fa2f7ff7a786f575b2bbf96",
  "038": "21b037e1d3eb3377d84937e50d71e222d19d5f532f1ec131693480eff6a83079",
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
  "051": "966311406354811714f7cf5289b45305a7f75a12669ed78db65a92102c91dff1",
  "052": "46b3bbe5a0af965b825c74e12306d9982a4d2ba97a06e7a3ea15d4b0c7020108",
  "053": "00f15de51ab9494a4e95dac6e67593c5c1daa6faaae2cb31ce1f9d97d5bdd07e",
  "054": "0c9c14b367c365dbc78c5082a36392d38c9f0afc9a7a2eac2623788abb6766bf",
  "055": "138784c7a90470fac1a996a69abad98b99c6086abcf1dc5916d60815b558e3d2",
  "056": "c4f0e9f49501100325f52c5ca2313c026a9ba94f46f2630cf1ed6d8463d241ce",
  "057": "acce09d3d47f97649a2a355b02b0393358cfc06485b3f790e0efec9fb593b199",
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
