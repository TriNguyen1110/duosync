import test from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import { validate, configuration, reply, createServer } from '../server/server.mjs';
const body = () => ({messages:[{role:'user',content:'Explain this'}], context:{title:'Lesson',url:'https://example.com',text:'Read this exact quote.',selection:'exact quote'}});
const env = {AI_PROVIDER:'openai', AI_MODEL:'test-model', OPENAI_API_KEY:'fake-test-key'};
const answer = () => new Response(JSON.stringify({output:[{content:[{type:'output_text',text:'Real transport test'}]}]}));
async function withServer(options, run) {
 const server = createServer(options); server.listen(0, '127.0.0.1'); await once(server,'listening');
 try { await run(`http://127.0.0.1:${server.address().port}`); }
 finally { server.closeAllConnections(); await new Promise(resolve=>server.close(resolve)); }
}
const post = (url, data=body(), headers={}) => fetch(url+'/api/chat',{method:'POST',headers:{'Content-Type':'application/json',...headers},body:JSON.stringify(data)});
test('validation rejects role injection, source mismatch and size violations',()=>{
 for (const mutate of [b=>b.messages[0].role='system',b=>b.context.selection='absent',b=>b.context.text='x'.repeat(12001),b=>b.messages[0].content='x'.repeat(4001),b=>b.messages=Array(21).fill({role:'user',content:'hi'}),b=>b.messages[0].role='assistant']) { const b=body(); mutate(b); assert.throws(()=>validate(b)); }
 assert.deepEqual(validate(body()),body());
});
test('configuration needs explicit provider model and correct key',()=>{
 assert.equal(configuration({}).configured,false);
 assert.equal(configuration({...env,OPENAI_API_KEY:''}).configured,false);
 assert.equal(configuration({...env,AI_PROVIDER:'anthropic'}).configured,false);
 assert.equal(configuration(env).configured,true);
});
test('OpenAI mapping preserves untrusted source and disables storage',async()=>{
 let request;
 const result=await reply(body(),configuration(env),undefined,async(url, options)=>{ request={url,...options}; return answer(); });
 assert.equal(result.text,'Real transport test'); assert.equal(request.url,'https://api.openai.com/v1/responses');
 const payload=JSON.parse(request.body); assert.equal(payload.store,false); assert.equal(payload.model,'test-model');
 assert.match(payload.input[0].content,/untrusted source data/); assert.match(payload.instructions,/never instructions/);
 assert.deepEqual(payload.input[1],body().messages[0]);
});
test('Anthropic mapping extracts text blocks only',async()=>{
 let payload;
 const result=await reply(body(),{provider:'anthropic',model:'test',key:'fake'},undefined,async(url, options)=>{
 assert.equal(url,'https://api.anthropic.com/v1/messages'); assert.equal(options.headers['x-api-key'],'fake');
 payload=JSON.parse(options.body); return new Response(JSON.stringify({content:[{type:'text',text:'First'},{type:'thinking',text:'hidden'},{type:'text',text:'Second'}]})); });
 assert.equal(result.text,'First\nSecond'); assert.ok(payload.system); assert.equal(payload.max_tokens,1600);
});
test('provider auth/rate/empty errors never become replies',async()=>{
 for (const status of [401,403,429,500]) await assert.rejects(reply(body(),configuration(env),undefined,async()=>new Response('secret upstream',{status})),e=>e.status===502 && !e.message.includes('secret'));
 await assert.rejects(reply(body(),configuration(env),undefined,async()=>new Response('{}')),/no text/);
});
test('unconfigured server is honest and never calls provider',async()=>{
 await withServer({env:{},request:()=>assert.fail('Provider must not run')},async url=>{
 const response=await post(url); assert.equal(response.status,503); assert.match((await response.json()).error,/not configured/);
 const health=await (await fetch(url+'/api/health')).json(); assert.equal(health.configured,false);
 });
});
test('server rejects foreign origins and malformed JSON',async()=>{
 await withServer({env},async url=>{
 assert.equal((await post(url,body(),{Origin:'https://evil.example'})).status,403);
 assert.equal((await fetch(url+'/api/chat',{method:'POST',headers:{'Content-Type':'application/json'},body:'{broken'})).status,400);
 assert.equal((await post(url,{...body(),messages:[]})).status,400);
 });
});
test('configured HTTP path returns only mapped provider text',async()=>{
 await withServer({env,request:async()=>answer()},async url=>{
 const response=await post(url); assert.equal(response.status,200); assert.deepEqual(await response.json(),{text:'Real transport test'});
 });
});
test('timeout aborts provider and settles 504, next request can run',async()=>{
 let count=0, aborted=false;
 await withServer({env,timeoutMs:20,request:async(_url,{signal})=>{
 if (++count>1) return answer();
 return new Promise((_,reject)=>signal.addEventListener('abort',()=>{aborted=true; reject(new Error('aborted'));},{once:true}));
 }},async url=>{
 const response=await post(url); assert.equal(response.status,504); assert.equal(aborted,true);
 assert.equal((await post(url)).status,200);
 });
});
test('disconnect aborts provider',async()=>{
 let started, ended; const began=new Promise(r=>started=r), aborted=new Promise(r=>ended=r);
 await withServer({env,request:async(_url,{signal})=>new Promise((_,reject)=>{started();signal.addEventListener('abort',()=>{ended();reject(new Error('aborted'));},{once:true});})},async url=>{
 const controller=new AbortController();
 const pending=fetch(url+'/api/chat',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body()),signal:controller.signal}).catch(()=>{});
 await began; controller.abort(); await pending;
 await Promise.race([aborted,new Promise((_,reject)=>setTimeout(()=>reject(new Error('Provider not cancelled')),1000))]);
 });
});

test('gpt-5-nano minimal reasoning mapping keeps phone response budget',async()=>{
 let payload;
 await reply(body(),configuration({...env,AI_MODEL:'gpt-5-nano'}),undefined,async(_url, options)=>{payload=JSON.parse(options.body);return answer();});
 assert.deepEqual(payload.reasoning,{effort:'minimal'}); assert.equal(payload.model,'gpt-5-nano'); assert.equal(payload.max_output_tokens,1600);
});
