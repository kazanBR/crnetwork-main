document.body.addEventListener("click", () => {
    const unlock = new Audio();
    unlock.volume = 0;
    unlock.play().catch(() => {});
}, { once: true });

const { useState, useEffect } = React;

// Ícones
const Icons = {};
Icons.Menu = () => React.createElement("svg", {width:24,height:24,viewBox:"0 0 24 24", fill:"none", stroke:"currentColor", strokeWidth:2}, React.createElement("line",{x1:4,y1:12,x2:20,y2:12}), React.createElement("line",{x1:4,y1:6,x2:20,y2:6}), React.createElement("line",{x1:4,y1:18,x2:20,y2:18}));
Icons.ChevronLeft = () => React.createElement("svg", {width:24,height:24,viewBox:"0 0 24 24", fill:"none", stroke:"currentColor", strokeWidth:2}, React.createElement("path",{d:"m15 18-6-6 6-6"}));
Icons.ChevronRight = () => React.createElement("svg", {width:24,height:24,viewBox:"0 0 24 24", fill:"none", stroke:"currentColor", strokeWidth:2}, React.createElement("path",{d:"m9 18 6-6-6-6"}));
Icons.Activity = () => React.createElement("svg", {width:24,height:24,viewBox:"0 0 24 24", fill:"none", stroke:"currentColor", strokeWidth:2}, React.createElement("path",{d:"M22 12h-4l-3 9L9 3l-3 9H2"}));
Icons.Zap = () => React.createElement("svg", {width:24,height:24,viewBox:"0 0 24 24", fill:"none", stroke:"currentColor", strokeWidth:2}, React.createElement("polygon",{points:"13 2 3 14 12 14 11 22 21 10 12 10 13 2"}));
Icons.RotateCcw = () => React.createElement("svg", {width:24,height:24,viewBox:"0 0 24 24", fill:"none", stroke:"currentColor", strokeWidth:2}, React.createElement("path",{d:"M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"}), React.createElement("path",{d:"M3 3v5h5"}));
Icons.Thermometer = () => React.createElement("svg",{width:12,height:12,viewBox:"0 0 24 24", fill:"none", stroke:"currentColor", strokeWidth:2}, React.createElement("path",{d:"M14 14.76V3.5a2.5 2.5 0 0 0-5 0v11.26a4.5 4.5 0 1 0 5 0z"}));
Icons.Battery = () => React.createElement("svg",{width:12,height:12,viewBox:"0 0 24 24", fill:"none", stroke:"currentColor", strokeWidth:2}, React.createElement("rect",{width:16,height:10,x:2,y:7,rx:2,ry:2}));
Icons.Flame = () => React.createElement("svg",{width:24,height:24,viewBox:"0 0 24 24", fill:"none", stroke:"currentColor", strokeWidth:2}, React.createElement("path",{d:"M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.1.2-2.2.6-3.3.7 2.22 1.9 3.8 2.9 5.3z"}));


// APP
function App(){
  const [currentScreen,setCurrentScreen] = useState('menu');
  // Inicializa com dados seguros
  const [data,setData] = useState({ rpm:0, tps:0, temp:60, fuel:100 });
  const [tuneConfig, setTuneConfig] = useState({}); 

  useEffect(()=> {
    const handle = (e) => {
      const item = e.data;
      if(!item) return;
      
      // Recebe os dados do loop do cliente
      if(item.action === "updateDash") {
          setData(prev => ({...prev, ...item.data}));
      }
      
      if(item.action === "loadTune") {
        setTuneConfig(item.data || {});
      }
    };
    window.addEventListener('message', handle);
    return ()=> window.removeEventListener('message', handle);
  },[]);

  const postNui = (endpoint, body) => {
    const resName = 'athlon-app-lb';
    setTuneConfig(prev => ({...prev, ...body}));
    
    fetch(`https://${resName}/${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    }).catch(e => console.log("NUI Post Error", e));
  };

  const renderScreen = () => {
    switch(currentScreen){
      case 'dash': return React.createElement(DashboardScreen, {onBack:()=>setCurrentScreen('menu'), data});
      case 'corte': return React.createElement(RevLimiterScreen, {onBack:()=>setCurrentScreen('menu'), postNui, tuneConfig});
      case 'lenta': return React.createElement(IdleScreen, {onBack:()=>setCurrentScreen('menu'), postNui, tuneConfig});
      default: return React.createElement(MainMenu, {onSelect:setCurrentScreen});
    }
  };

  return React.createElement('div', {className:"w-full h-full bg-slate-50 flex flex-col font-sans"}, React.createElement('div',{className:"flex-1 overflow-y-auto overflow-x-hidden"}, renderScreen()));
}

// --- Components ---

function MainMenu({onSelect}){
  return React.createElement('div',{className:"p-6 pt-24 flex flex-col gap-4"},
    React.createElement('div',{className:"mb-6 text-center"},
      React.createElement('h1',{className:"text-3xl font-extrabold text-blue-600 tracking-tighter"},"ATHLON"),
      React.createElement('p',{className:"text-gray-400 text-sm"},"ECU MANAGER V2.3")
    ),
    React.createElement(MenuButton,{icon:React.createElement(Icons.Activity,null), title:"Dash", sub:"Monitoramento", onClick:()=>onSelect('dash')}),
    React.createElement(MenuButton,{icon:React.createElement(Icons.Zap,null), title:"Corte de Giro", sub:"Configurar limitador", onClick:()=>onSelect('corte')}),
    React.createElement(MenuButton,{icon:React.createElement(Icons.RotateCcw,null), title:"Marcha Lenta", sub:"Ponto morto explosivo", onClick:()=>onSelect('lenta')})
  );
}

function DashboardScreen({onBack, data}){
  // Garante que são números e arredonda
  const rpm = Math.round(data.rpm || 0);
  const tps = Math.round(data.tps || 0);
  const temp = Math.round(data.temp || 0);
  const fuel = Math.round(data.fuel || 0);
  
  // Cálculo da barra SVG (0 a 12000 rpm)
  const maxRpm = 12000;
  const dashOffset = 251 - (251 * (Math.min(rpm, maxRpm) / maxRpm));

  return React.createElement('div',{className:"flex flex-col min-h-full bg-white pb-20"},
    React.createElement(Header,{title:"Dash", onBack}),
    React.createElement('div',{className:"p-4 flex flex-col items-center border-b border-slate-100 pb-6 relative"},
      React.createElement('div',{className:"relative w-64 h-32 mb-2 overflow-hidden"},
        React.createElement('svg',{viewBox:"0 0 200 110", className:"w-full h-full"},
          React.createElement('path',{d:"M 20 100 A 80 80 0 0 1 180 100", fill:"none", stroke:"#e2e8f0", strokeWidth:15, strokeLinecap:"round"}),
          // Barra de progresso dinâmica
          React.createElement('path',{
              d:"M 20 100 A 80 80 0 0 1 180 100", 
              fill:"none", 
              stroke: (rpm > 9000 ? "#ef4444" : "#3b82f6"), // Vermelho se passar de 9k
              strokeWidth:15, 
              strokeLinecap:"round", 
              strokeDasharray:251, 
              strokeDashoffset: dashOffset 
          })
        ),
        React.createElement('div',{className:"absolute bottom-0 w-full text-center"},
          React.createElement('div',{className:"text-xs text-slate-400 font-bold uppercase tracking-widest"},"RPM"),
          React.createElement('div',{className:"text-4xl font-black text-slate-800"}, rpm)
        )
      ),
      React.createElement('div',{className:"flex w-full justify-between gap-4 px-2"},
        React.createElement('div',{className:"flex flex-col w-12 gap-1 items-center"},
          React.createElement('div',{className:"h-24 w-4 bg-slate-100 rounded-full relative overflow-hidden"},
            React.createElement('div',{className:"absolute bottom-0 w-full bg-green-500 transition-all duration-100", style:{height: tps + '%'}})
          ),
          React.createElement('span',{className:"text-[10px] font-bold text-slate-500"},"TPS")
        ),
        React.createElement('div',{className:"flex-1 grid grid-cols-2 gap-2 text-[10px] font-medium text-slate-500 bg-slate-50 p-2 rounded-lg h-fit"},
          React.createElement('div',{className:"flex items-center gap-1"}, React.createElement(Icons.Thermometer,{}), " Ar: 26°C"),
          React.createElement('div',{className:"flex items-center gap-1"}, React.createElement(Icons.Thermometer,{}), " Ign: 45°C"),
          React.createElement('div',{className:"flex items-center gap-1"}, React.createElement(Icons.Battery,{}), " Bat: 12.5V"),
          React.createElement('div',{className:"text-blue-600 font-bold"},"S7: ON")
        ),
        React.createElement('div',{className:"flex flex-col w-12 gap-1 items-center"},
          React.createElement('div',{className:"h-24 w-4 bg-slate-100 rounded-full relative overflow-hidden"},
            React.createElement('div',{className:"absolute bottom-0 w-full bg-purple-500 h-[60%]"})
          ),
          React.createElement('span',{className:"text-[10px] font-bold text-slate-500"},"AFR")
        )
      )
    ),
    React.createElement('div',{className:"p-4 grid grid-cols-2 gap-x-8 gap-y-2 text-xs font-mono bg-white"},
      React.createElement(DataItem,{label:"Rpm", value:rpm}),
      React.createElement(DataItem,{label:"Tps", value:tps + "%"}),
      React.createElement(DataItem,{label:"T Motor", value: temp + "°C"}),
      React.createElement(DataItem,{label:"Tanque", value: fuel + "%"}),
      React.createElement(DataItem,{label:"Lambda", value:"0.92"})
    )
  );
}

function IdleScreen({onBack, postNui, tuneConfig}){
  const [idlePop, setIdlePop] = useState(tuneConfig.idlePop || false);

  useEffect(() => {
    setIdlePop(tuneConfig.idlePop || false);
  }, [tuneConfig]);

  const handleToggle = (val) => {
    setIdlePop(val);
    postNui('saveData', { idlePop: val });
  };

  return React.createElement('div',{className:"bg-slate-50 h-full flex flex-col"},
    React.createElement(Header,{title:"Marcha Lenta", onBack}),
    React.createElement('div',{className:"p-4 flex-1"},
      React.createElement('div',{className:"bg-white rounded-xl shadow-sm p-4 mb-4"},
        React.createElement('div',{className:"flex items-center gap-4 mb-2"},
            React.createElement('div',{className:"p-2 bg-orange-100 text-orange-600 rounded-lg"}, React.createElement(Icons.Flame)),
            React.createElement('div', null, 
                React.createElement('h3',{className:"font-bold text-slate-800"}, "Ponto Morto Explosivo"),
                React.createElement('p',{className:"text-xs text-slate-400"}, "Estouros aleatórios em baixa rotação")
            )
        ),
        React.createElement('div',{className:"mt-4 flex items-center justify-between"},
            React.createElement('span',{className:"text-sm font-medium text-slate-600"}, idlePop ? "ATIVADO" : "DESATIVADO"),
            React.createElement(ToggleSwitch, { checked: idlePop, onChange: handleToggle })
        )
      ),
      React.createElement('p',{className:"text-xs text-slate-400 text-center px-4"}, "Atenção: Esta função fará a moto soltar estouros e fogo pelo escape quando estiver parada ou em marcha lenta sem acelerar.")
    )
  );
}

function RevLimiterScreen({onBack, postNui, tuneConfig}){
  const [cutType, setCutType] = useState(tuneConfig.cutType || 'ignicao');
  const [rpmLimit, setRpmLimit] = useState(tuneConfig.rpmLimit || 10700);

  useEffect(() => {
      if(tuneConfig.cutType) setCutType(tuneConfig.cutType);
      if(tuneConfig.rpmLimit) setRpmLimit(tuneConfig.rpmLimit);
  }, [tuneConfig]);

  const handleSave = () => {
    postNui('saveData', { cutType, rpmLimit });
    onBack();
  };

  return React.createElement('div',{className:"bg-slate-50 h-full flex flex-col"},
    React.createElement(Header,{title:"Corte de giro", onBack}),
    React.createElement('div',{className:"p-4 flex-1"},
      React.createElement('h2',{className:"text-xs font-bold text-slate-400 uppercase tracking-wider mb-4"},"Modo de Corte"),
      React.createElement('div',{className:"bg-white rounded-xl shadow-sm overflow-hidden mb-8"},
        React.createElement(RadioOption,{label:"Sem corte", checked: cutType === 'none', onChange: ()=>setCutType('none')}),
        React.createElement(RadioOption,{label:"Corte Injeção", checked: cutType === 'injecao', onChange: ()=>setCutType('injecao')}),
        React.createElement(RadioOption,{label:"Corte Ignição", checked: cutType === 'ignicao', onChange: ()=>setCutType('ignicao')})
      ),
      React.createElement('div',{className:"bg-white rounded-xl shadow-sm p-6 flex flex-col items-center"},
        React.createElement('div',{className:"flex justify-between w-full text-xs font-bold text-slate-400 mb-2"}, React.createElement('span',null,"8900"), React.createElement('span',null,"12000")),
        React.createElement('input',{type:"range", min:8900, max:12000, step:50, value:rpmLimit, onChange:(e)=>setRpmLimit(e.target.value), className:"w-full h-2 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-blue-500 mb-6"}),
        React.createElement('div',{className:"text-center"}, React.createElement('span',{className:"text-sm text-slate-500 font-medium"},"Limite Atual:"), React.createElement('div',{className:"text-4xl font-black text-slate-800 mt-1"}, rpmLimit + " RPM"))
      ),
      React.createElement('button',{onClick:handleSave, className:"mt-6 w-full py-4 bg-blue-600 text-white font-bold rounded-xl shadow-lg active:scale-95 transition-transform"},"SALVAR")
    )
  );
}

function ToggleSwitch({checked, onChange}){ return React.createElement('div', { className: `w-14 h-8 flex items-center rounded-full p-1 cursor-pointer transition-colors duration-300 ${checked ? 'bg-blue-600' : 'bg-slate-300'}`, onClick: () => onChange(!checked) }, React.createElement('div', { className: `bg-white w-6 h-6 rounded-full shadow-md transform transition-transform duration-300 ${checked ? 'translate-x-6' : 'translate-x-0'}` })); }
function MenuButton({icon, title, sub, onClick}){ return React.createElement('button',{onClick, className:"flex items-center gap-4 p-4 bg-white rounded-2xl shadow-sm border border-slate-100 active:scale-95 transition-all hover:border-blue-300 group w-full"}, React.createElement('div',{className:"w-12 h-12 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center"}, icon), React.createElement('div',{className:"text-left flex-1"}, React.createElement('h3',{className:"font-bold text-slate-800"}, title), React.createElement('p',{className:"text-xs text-slate-400"}, sub)), React.createElement(Icons.ChevronRight,null)); }
function Header({title, onBack}){ return React.createElement('div',{className:"flex items-center justify-between px-4 pb-4 pt-16 bg-white border-b border-slate-100 sticky top-0 z-10 shadow-sm shrink-0"}, React.createElement('button',{onClick:onBack, className:"flex items-center text-blue-500 font-medium active:opacity-50"}, React.createElement(Icons.ChevronLeft,null), " Back"), React.createElement('span',{className:"font-bold text-slate-800"}, title), React.createElement('div',{className:"w-8"})); }
function DataItem({label, value}){ return React.createElement('div',{className:"flex justify-between border-b border-slate-50 py-1"}, React.createElement('span',{className:"text-slate-500 font-semibold"}, label+":"), React.createElement('span',{className:"text-slate-800 font-bold"}, value)); }
function RadioOption({label, checked, onChange}){ return React.createElement('div',{onClick:onChange, className:"flex items-center justify-between p-4 border-b border-slate-50 last:border-0 cursor-pointer active:bg-slate-50"}, React.createElement('span',{className:"font-medium text-slate-700"}, label), checked ? React.createElement('div',{className:"text-blue-500"},"✔") : null); }

window.addEventListener("message", (event) => {
    if (event.data.action === "pipoco") {
        const audio = new Audio("nui://athlon-app-lb/web/sounds/pipoco.ogg");
        audio.volume = event.data.intensity || 1.0;
      
    }
});

ReactDOM.createRoot(document.getElementById('root')).render(React.createElement(App));