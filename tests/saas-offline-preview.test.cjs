"use strict";
const test=require("node:test"), assert=require("node:assert/strict");
const fs=require("node:fs"), os=require("node:os"), path=require("node:path");
const vm=require("node:vm"), crypto=require("node:crypto"), {spawnSync}=require("node:child_process");
const root=path.resolve(__dirname,".."), temporary=fs.mkdtempSync(path.join(os.tmpdir(),"f5-saas-preview-test-"));
const generated=spawnSync(process.platform==="win32"?"py":"python3",[...(process.platform==="win32"?["-3"]:[]),"-B","-c",[
  "import sys,json,zipfile,pathlib",
  "sys.path.insert(0,str(pathlib.Path(sys.argv[1])/'scripts'))",
  "import build_saas_offline_preview as builder",
  "receipt=builder.build(pathlib.Path(sys.argv[1]),pathlib.Path(sys.argv[2]))",
  "with zipfile.ZipFile(pathlib.Path(sys.argv[2])/builder.PACKAGE_NAME) as archive:",
  " print(json.dumps({'html':archive.read('index.html').decode(),'manifest':json.loads(archive.read('demo-manifest.json')),'entries':archive.namelist(),'receipt':receipt}))"
].join("\n"),root,temporary],{encoding:"utf8"});
if(generated.status!==0) throw new Error(generated.stderr||generated.stdout);
const exact=JSON.parse(generated.stdout), html=exact.html;
// Delete only the test-owned temporary directory after verifying its parent.
if(path.dirname(temporary)!==path.resolve(os.tmpdir())||!path.basename(temporary).startsWith("f5-saas-preview-test-")) throw new Error("Unexpected temporary path");
fs.rmSync(temporary,{recursive:true});
const dataMatch=html.match(/<script id="preview-data" type="application\/json">([\s\S]*?)<\/script>/);
const script=html.match(/<script>\s*([\s\S]*?)<\/script>/)[1];
const catalog=JSON.parse(fs.readFileSync(path.join(root,"demo/assets/dominion-saas-catalog.json"),"utf8"));
class Element {
  constructor(){this.textContent="";this.disabled=false;this.attributes={};this.listeners={};this.children=[];}
  setAttribute(name,value){this.attributes[name]=value;}
  addEventListener(name,callback){this.listeners[name]=callback;}
  replaceChildren(...children){this.children=children;}
  click(){if(!this.disabled)this.listeners.click?.();}
}
function fixture(){
  const elements=new Map([...html.matchAll(/\bid="([^"]+)"/g)].map(match=>[match[1],new Element()]));
  elements.get("preview-data").textContent=dataMatch[1];
  const modules=Array.from({length:13},()=>new Element());
  let attempts=0;
  const prohibited=()=>{attempts++;throw new Error("Browser I/O is prohibited");};
  const document={getElementById:id=>{if(!elements.has(id))throw new Error("Missing element "+id);return elements.get(id);},querySelectorAll:selector=>{assert.equal(selector,"[data-module]");return modules;},createElement:tag=>{assert.equal(tag,"li");return new Element();}};
  const context=vm.createContext({document,fetch:prohibited,XMLHttpRequest:prohibited,WebSocket:prohibited,EventSource:prohibited,Worker:prohibited,setTimeout:prohibited,setInterval:prohibited,requestAnimationFrame:prohibited,localStorage:new Proxy({},{get:prohibited}),sessionStorage:new Proxy({},{get:prohibited}),navigator:new Proxy({},{get:prohibited}),location:new Proxy({},{get:prohibited})},{codeGeneration:{strings:false,wasm:false}});
  vm.runInContext(script,context,{timeout:1000});
  return {elements,modules,click:id=>elements.get(id).click(),run:code=>vm.runInContext(code,context,{timeout:1000}),state:()=>JSON.parse(vm.runInContext("JSON.stringify(sampleState())",context)),attempts:()=>attempts};
}
function atApproval(f){f.click("advance");f.click("advance");}
function complete(f){atApproval(f);f.click("approve");f.click("advance");}

test("executed HTML is extracted from the real deterministic four-file ZIP",()=>{
  const hash=crypto.createHash("sha256").update(html).digest("hex");
  assert.equal(hash,exact.manifest.source.inputRawHtmlSha256);
  assert.equal(hash,exact.receipt.generatedOfflineHtmlSha256);
  assert.deepEqual(exact.entries,["DEMO-TERMS.txt","README.txt","demo-manifest.json","index.html"]);
  assert.equal(exact.manifest.moduleCount,13);
  assert.equal(exact.manifest.googleDeploymentCertified,false);
  assert.equal(exact.manifest.actualSaasImplementationsIncluded,false);
});
test("all 13 catalogue identities and Coming Soon states survive into the executable samples",()=>{
  const data=JSON.parse(dataMatch[1]);assert.equal(data.modules.length,13);
  for(let index=0;index<13;index++){
    const actual=data.modules[index], canonical=catalog.modules[index];
    for(const key of ["id","name","store_state","implementation_state","standalone_ga"]) assert.deepEqual(actual[key],canonical[key]);
    assert.deepEqual(Object.keys(actual.examples),["business","politics"]);
    assert.notEqual(actual.examples.business.title,actual.examples.politics.title);
  }
});
test("starts without progression, authority, receipts, timers, or I/O",()=>{
  const f=fixture();assert.equal(f.state().receipts.length,0);assert.ok(f.state().states.every(state=>state.stage===0&&!state.approved));assert.equal(f.attempts(),0);
  assert.equal(f.elements.get("approve").disabled,true);
});
for(const mode of ["business","politics"]){
  test(mode+": all 13 examples require explicit approval and issue exactly one bound receipt",()=>{
    const f=fixture();if(mode==="politics")f.click("politics-mode");
    for(let index=0;index<13;index++){
      f.modules[index].click();atApproval(f);
      assert.equal(f.elements.get("advance").disabled,true);
      f.run("advance();approve();");
      assert.equal(f.state().receipts.length,index);
      assert.equal(f.state().states[index].stage,2);
      f.click("advance");f.run("advance();approve();");
      assert.equal(f.state().receipts.length,index+1);
      assert.equal(f.state().receipts[index].module,catalog.modules[index].name);
      assert.equal(f.state().receipts[index].mode,mode);
      assert.equal(f.state().states[index].stage,3);
    }
    assert.equal(f.elements.get("receipt-count").textContent,"13");assert.equal(f.elements.get("receipts").children.length,13);assert.equal(f.attempts(),0);
  });
  test(mode+": Hold blocks approval/progression in every module, including direct handler calls",()=>{
    const f=fixture();if(mode==="politics")f.click("politics-mode");atApproval(f);f.click("hold");
    const before=f.state();f.run("approve();advance();");assert.deepEqual(f.state(),before);
    for(let index=0;index<13;index++){
      f.modules[index].click();const stage=f.state().states[index].stage;
      f.run("approve();advance();");assert.equal(f.state().states[index].stage,stage);assert.equal(f.elements.get("advance").disabled,true);assert.equal(f.elements.get("approve").disabled,true);
    }
    f.modules[0].click();f.click("hold");f.click("approve");f.click("advance");assert.equal(f.state().receipts.length,1);assert.equal(f.attempts(),0);
  });
}
test("Hold remains explicit across reset and mode changes",()=>{
  const f=fixture();f.click("hold");f.click("reset");assert.equal(f.state().held,true);f.click("politics-mode");assert.equal(f.state().held,true);f.run("advance();approve();");assert.equal(f.state().states[0].stage,0);f.click("hold");f.click("advance");assert.equal(f.state().states[0].stage,1);
});
test("reset clears all module progress, approvals and receipts",()=>{
  const f=fixture();for(let index=0;index<13;index++){f.modules[index].click();complete(f);}f.click("reset");const state=f.state();assert.equal(state.selected,0);assert.equal(state.mode,"business");assert.equal(state.receipts.length,0);assert.ok(state.states.every(item=>item.stage===0&&!item.approved));assert.equal(f.elements.get("receipt-count").textContent,"0");
});
test("both mode transitions clear approvals and receipts and cannot reuse stale authority",()=>{
  const f=fixture();complete(f);f.modules[1].click();atApproval(f);f.click("approve");f.click("politics-mode");assert.equal(f.state().receipts.length,0);assert.ok(f.state().states.every(state=>state.stage===0&&!state.approved));atApproval(f);f.run("advance()");assert.equal(f.state().receipts.length,0);f.click("approve");f.click("advance");f.click("business-mode");assert.equal(f.state().receipts.length,0);assert.ok(f.state().states.every(state=>state.stage===0&&!state.approved));
});
test("module selection preserves its review while approvals never leak to another module",()=>{
  const f=fixture();atApproval(f);f.click("approve");f.modules[1].click();atApproval(f);f.run("advance()");assert.equal(f.state().receipts.length,0);assert.equal(f.state().states[1].approved,false);f.modules[0].click();assert.equal(f.state().states[0].approved,true);f.click("advance");assert.equal(f.state().receipts[0].module,"GrantConnect");
});
test("approval outside the review stage and invalid module/mode choices are inert",()=>{
  const f=fixture();const state=f.state();f.run("approve();selectModule(-1);selectModule(13);selectModule(0.5);changeMode('unknown');");assert.deepEqual(f.state(),state);f.click("advance");f.run("approve()");assert.equal(f.state().states[0].approved,false);
});
test("native buttons, CSP and fixed data expose no input, resource, navigation or storage sink",()=>{
  assert.match(html,/connect-src 'none'/);assert.match(html,/form-action 'none'/);assert.match(html,/No real authority or external action/);
  assert.doesNotMatch(html,/<(?:form|input|textarea|select|iframe|img|link|object|embed|video|audio)\b/i);
  assert.doesNotMatch(html,/\b(?:src|href|action|formaction|srcset|poster)\s*=/i);
  assert.doesNotMatch(script,/\b(?:fetch|XMLHttpRequest|WebSocket|EventSource|sendBeacon|Worker|setTimeout|setInterval|requestAnimationFrame|eval|Function|localStorage|sessionStorage|indexedDB|navigator|location|innerHTML|outerHTML|insertAdjacentHTML|document\.write)\b/);
  assert.equal((html.match(/data-module="\d+"/g)||[]).length,13);
});
test("download record and Squarespace activation remain pending",()=>{
  const status=JSON.parse(fs.readFileSync(path.join(root,"demo/assets/saas-offline-preview-download.json"),"utf8"));assert.equal(status.publicUrl,null);assert.equal(status.packageSha256,null);assert.equal(status.googleDeployment.certification,"PENDING");
  const page=fs.readFileSync(path.join(root,"squarespace/demo-1-final.html"),"utf8");assert.ok(page.includes('data-google-certification="pending"'));assert.equal(exact.manifest.publicationState,"PENDING_GOOGLE_CERTIFICATION");
});
