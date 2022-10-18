var debug= false;

HTMLWidgets.widget({

  name: 'amapro',
  type: 'output',

  factory: function(el, width, height) {

    var initialized= false;
    var opts;

    return {

      renderValue: function(x) {

        if (typeof AMap==='undefined') {
          alert("Check for AMap library file 'amap.js' and try again"); return; }
        if (x.hasOwnProperty('debug'))
          debug = x.debug;
        
        m$jmap = new AMap.Map(document.getElementById(el.id), x.opts);
        
        if (x.hasOwnProperty('loca')) {
          if (x.loca) {
            if (typeof Loca==='undefined') {
              alert('Check for Loca library and try again'); return; }
            m$loca = new Loca.Container({ map: m$jmap });
          }
        }
        
        if (!initialized) {
          initialized = true;
          setEvents(x.opts, 'm$jmap');
          //if (m$loca) setEvents?
        }
    
        var that = this;
        // after initialization, call any outstanding API functions (per D.Attali)
        var numApiCalls = x['api'].length;
        for (var i = 0; i < numApiCalls; i++) {
          var call = x['api'][i];
          var method = call.method;
          delete call['method'];
          try {
            that[method](call);
          } catch(err) {}
        }

	    },   // end renderValue

      addControl: function(args) {
        tdat = (typeof args.data=='object' && args.data.length==0) ? '' : 'args.data';
        tmp = 'm$jmap.addControl(new AMap.'+ args.type +'('+tdat+'));';
        sval(tmp, args);
      },

      addItem: function(args) {
        if (args.data.name)     // replace name with iname
          delete Object.assign(args.data, {['iname']: args.data.name })['name'];
        args.cmd = 'set';
        args.target = args.type;
        cmdo(args); 
      },

      addCmd: function(args) {    // from am.cmd(cmd, target, etc)
        cmdo(args);
      },

      getjmap: function(){ return m$jmap; },

      getOpts: function(){ return opts; },

      resize: function(width, height) {
        if (m$jmap)
          m$jmap.resize({width: width, height: height});
      }

    };
  }
});

function get_amap(id){

  let htmlWidgetsObj = HTMLWidgets.find("#" + id);
  if (!htmlWidgetsObj) return(null);

  let dmap;

  if (typeof htmlWidgetsObj != 'undefined') {
    dmap = htmlWidgetsObj.getjmap();
  }

  return(dmap);
}

function get_amap_opts(id){

  let htmlWidgetsObj = HTMLWidgets.find("#" + id);
  if (!htmlWidgetsObj) return(null);

  let opts;

  if (typeof htmlWidgetsObj != 'undefined')
    opts = htmlWidgetsObj.getOpts();

  return(opts);
}

function setPrelims(args) {
  if (args.data.bounds) {  //Rectangle corners: SouthWest, NorthEast
      tmp= args.data.bounds;
      args.data.bounds= new AMap.Bounds(tmp[0], tmp[1]);
  }
  if (args.data.icon && typeof args.data.icon == 'string' &&
      !args.data.icon.startsWith('http') )   // named icon
    sval("args.data.icon="+args.data.icon+";", args);
  return args;
}

function setEvents(adata, dname) {

  if(adata.on) {
    for(var ev = 0; ev < adata.on.length; ev++){
      //event = adata.on[ev][0];  last = adata.on[ev][2];
      //handler = last ? last : adata.on[ev][1]
      //query =   last ? "'" + adata.on[ev][1]+"', " : ''
      event= (adata.on[ev].e) ? adata.on[ev].e : null;
      handler= (adata.on[ev].f) ? adata.on[ev].f : null;
      if (!event || !handler) { console.log('missing event name or handler'); return; }
      query= (adata.on[ev].q) ? adata.on[ev].q : '';
      sval(dname+".on('"+event+"', "+query + handler+"); ", null)
    }
  }
  if(adata.off) {
    for(var ev = 0; ev < adata.off.length; ev++){
      event= (adata.off[ev].e) ? adata.off[ev].e : null;
      handler= (adata.off[ev].f) ? adata.off[ev].f : null;
      if (!event || !handler) { console.log('missing event name or handler'); return; }
      query= (adata.off[ev].q) ? adata.off[ev].q : '';
      sval(dname+".on('"+event+"', "+query + handler+"); ", null)
    }
  }
}

function sval(str, args, quiet=false) {
    if (debug) console.log(str+' => '+JSON.stringify(args) );
    try {
      eval(str);
    } catch(err) {
      if (!quiet) console.log('sval:'+str+' \n '+ err.message);
      return false;
    }
    return true;
}

function cmdo(args) { 
  if (args.cmd=='addTo') args.cmd = 'add';  // do not use AMap own cmd addTo(map) 
  args = setPrelims(args);
  dname = args.data.name;
  if (dname) delete args.data.name;
  // convert from string to function if any
  Object.entries(args.data).map(([k, v]) => { if (v.toString().startsWith('function')) eval("args.data."+k+" = "+v+";"); });
  
  if (args.target=='' || args.target=='map') // !args.target || 
    args.target = 'm$jmap';
  else if (args.cmd!='set' && args.cmd!='code')
    args.target = 'window.'+args.target;
  tdata = '(args.data);';
  if (typeof args.data=='string') {
    //if (sval(args.data, args, true))  // valid object
    //  sval('args.data='+args.data, args);
  }
  if (Object.values(args.data) && !Object.keys(args.data).some(isNaN))   // unnamed only
	  args.data = Object.values(args.data);
	if (typeof args.data=='object' && args.data.length) {  // args.data like [1,2]
    tdata = '(';
    // if object valid, set one unnamed variable or a string
    args.data.map(x => {
      tmp = sval(x, args, true) ? x : '"'+x+'"';
      if (typeof tmp=='object' && tmp.length) {
        arr = '[';
        tmp.map(y => {arr= arr + (eval(y) ? y : '"'+y+'"') +','; });
        tmp = arr.replace(/.$/, ']');
      }
      tdata = tdata + tmp + ',';
    });
    tdata = tdata.replace(/.$/, ');');
  } 
  else
    if (args.cmd.startsWith('set') && args.cmd.length>3 &&
      !'setOptions setParams setIcon setText setStyle setFitView'.includes(args.cmd)) {
        if (args.cmd.indexOf('(') >0)
          tdata = '';
        else
          tdata ="(...Object.values(args.data))";  //for setZoomAndCenter, setRotation, etc
  }
  
  if (args.cmd.startsWith('get')) {     // changes .source - keep code here
    if (args.cmd.indexOf('(') >0)     // params already inside cmd
      tdata = ';';
    args.target = 'var tmp='+args.target;
    if (!args.data.f)
      args.data.f = 'function(x) {return x;}';
    sval('tefu= '+args.data.f, args, true);  // set function to apply
    shin = args.data.r  // save Shiny input name
    delete args.data.r; delete args.data.f   // to not interfere with real getX params
    tdata = tdata + " tmp= tefu(tmp); Shiny.setInputValue('"+shin+"', tmp)";
  }
  
  if (args.cmd=='set') {
    if (dname)
      tmp = 'window.'+dname+ '= new AMap.'+ args.target +tdata;
    else if (args.data.iname) {   // comes from addItem
      dname = args.data.iname;    // set for events if any
      tmp = 'window.'+dname+ '= new AMap.'+ args.target +tdata+
        'm$jmap.add(' +dname+');';
    } 
    else {
      tdata = tdata.replace(');', '));')
      tmp = 'm$jmap.add(new AMap.'+ args.target + tdata;
    }
  } else if (args.cmd=='code') {
    tmp = args.target;
  } else if (args.cmd=='prop') {
    tmp = args.target +'.'+ Object.keys(args.data)[0] + '=Object.values(args.data)[0];';
  } else if (args.cmd=='var') {
    tmp = args.target + '=args.data[0];';
  } else
    tmp = args.target +'.'+ args.cmd +tdata;

  cmdType(tmp, args, dname);

  if(!dname) return;  // set events for named objects only
  // handle object events  obj.on('event', func)
  setEvents(args.data, dname);
}

function cmdType(madd, args, zname) {
  if (args.cmd=='code') {
    sval(madd, args); return;
  }
  
  target = args.target.replace('window.','');   // for cleaner switch argument

  switch(target) {

  case 'Polyline':
  case 'Icon':
  case 'Circle':
  case 'CircleMarker':
  case 'Ellipse':
  case 'Polygon':
  case 'Rectangle':
  case 'Text':
  case 'LabelMarker':
  case 'ElasticMarker':
  case 'InfoWindow':
  case 'ImageLayer':
  case 'VectorLayer':
  case 'LabelsLayer':
  case 'GeoJSON':
  case 'convertFrom':
      sval(madd, args);
      break;
    
  case 'Marker':
    if (!args.data.icon) {
      args.data.icon = 'https://a.amap.com/jsapi_demos/static/demo-center/icons/poi-marker-default.png';
      args.data.offset = new AMap.Pixel(-25,-50);
    }
    sval(madd, args);
    break;

  case 'MassMarks':
    if (!args.data.data) break;
    mdata = Object.values(args.data.data);
    delete args.data.data;
    
    if (!args.data.style)   // set default style
      args.data.style = [{
          url: 'https://webapi.amap.com/images/mass/mass0.png',
          anchor: new AMap.Pixel(6, 6),
          size: new AMap.Size(11, 11),
          zIndex: 1
      }, {
          url: 'https://webapi.amap.com/images/mass/mass1.png',
          anchor: new AMap.Pixel(4, 4),
          size: new AMap.Size(7, 7),
          zIndex: 2
      }, {
          url: 'https://webapi.amap.com/images/mass/mass2.png',
          anchor: new AMap.Pixel(3, 3),
          size: new AMap.Size(5, 5),
          zIndex: 3
      }];
    if (zname)
      tmp= zname+'= new AMap.MassMarks(mdata, args.data);';
    else
      tmp= 'm$massmarks= new AMap.MassMarks(mdata, args.data); m$massmarks.setMap(m$jmap);';
    sval(tmp, args);
    break;

  case 'Satellite':
  case 'RoadNet':
  case 'Traffic':
  case 'Flexible':
  case 'WMS':
  case 'WMTS':
    if (zname) {
      if (eval("typeof "+zname+"=='undefined'"))
        tmp = "window."+zname+"= new AMap.TileLayer."+
                target+"(args.data); "
      else tmp=''    // name exists already
      tmp = tmp + zname+'.setMap(m$jmap);'
    } else {
      vname = 'm$' + target.toLowerCase();
      tmp = 'var '+vname+'= new AMap.TileLayer.'+target+'(args.data); ' +
        vname+'.setMap(m$jmap);';
    }
    sval(tmp, args);
    break;

  case 'HeatMap':
    if (args.data.ddd) {   // R dislikes '3d' name
      args.data['3d'] = args.data.ddd;  delete args.data.ddd;
    }
    if (!args.data.pnts) {console.log(target+' has no data'); break;}
    if (typeof args.data.pnts == 'string')  // when heatmapData.js in header
      dastr= 'data:'+args.data.pnts;
    else {          // actual points;
      args.pnts = args.data.pnts;   // clean opts
      dastr= 'data:args.pnts';
    }
    delete args.data.pnts;
    tmp = '';
    if (eval("typeof "+zname+"=='undefined'")) {
      tmp = "window."+zname+"= new AMap."+target+"(m$jmap, args.data); ";
      tmp = tmp + zname + ".setDataSet({"+dastr+", max:100}); "
    }
    //tmp = tmp + zname+".show();"
    sval(tmp, args);
    break;

  case '3DTilesLayer':
    tmp = 'm$'+target+"= new AMap['"+target+"'](m$jmap, args.data);";
    sval(tmp, args);
    break;
    
  case 'Buildings':
  case 'MapboxVectorTileLayer':
    name = 'm$'+target;
    tmp = name+'= new AMap.'+target+'(args.data); '+name+'.setMap(m$jmap);';
    sval(tmp, args);
    break;

  case 'LayerGroup':  // for TileLayers only?
    // tmp == 'm$jmap.add(new AMap.LayerGroup([layer1,layer2]));'
    name = 'm$'+target;
    tmp = tmp.replace('m$jmap.add(', name+'= ').replace('));', '); '+name+'.setMap(m$jmap);');
    console.log(target+': '+tmp)
    sval(tmp, args);
    break;
    
  case 'OverlayGroup':  // for overlays (Marker,Circle,OverlayGroup,etc)
    if (tmp.indexOf('[')==-1) {
      tmp = tmp.replace(target+'(',target+'([');
      tmp = tmp.indexOf('));')==-1 ? tmp.replace(');', ']);') : tmp.replace('));', ']));');
    }
    //console.log(target+': '+tmp)
    sval(tmp, args);
    break;
    
  case 'MouseTool':
    if (args.cmd=='close') {
      m$jmap.remove(overlays);
      overlays = [];
      window.m$mousetool.close(true);
      window.m$mousetool = undefined;   // allow map to pan again
      break;
    }
    if (typeof window.m$mousetool=='undefined') {
      window.overlays = [];
      window.m$mousetool = new AMap.MouseTool(m$jmap);
      window.m$mousetool.on('draw', function(e){ overlays.push(e.obj); }) 
    }
    tmp = 'window.m$mousetool.'+args.cmd+'(args.data);';
    sval(tmp, args); 
    break;

  case 'CanvasLayer':
    if (!zname) break;
    if (!args.data.bounds) break;
    if (args.data.canvas) args.data.canvas = eval(args.data.canvas);
    sval(madd, args);
    break;
    
  // Loca elements ---------------------------------------
  
  case 'Container':
    if (zname) break;  // unique name m$loca
    tmp = "window.m$loca = new Loca.Container({ map: m$jmap });"
    sval(tmp, args);
    break;
    
  case 'GeoJSONSource':
    if (!zname) break;
    //if (!args.data.data) break;
    // data: geojson object OR url: 'http..'
    if (args.data.data)
      tmp = zname+"= new Loca.GeoJSONSource(args.data); ";
    else
      tmp = zname+"= new Loca.GeoJSONSource({url:'"+args.data.url+"'}); ";
    sval(tmp, args);
    break;

  case 'PolygonLayer':
  case 'ScatterLayer':
  case 'LinkLayer':
  case 'PulseLinkLayer':
  case 'LineLayer':
  case 'PulseLineLayer':
    if (!zname) break;
    args.data.loca = m$loca;
    tmp = zname+'= new Loca.'+target+'(args.data); ';
    sval(tmp, args);
    break;
  
  default:
    sval(madd, args);

  }  // end switch
}

if (HTMLWidgets.shinyMode) {

  Shiny.addCustomMessageHandler('amapro:doCmd', function(args) {
    var m$jmap = get_amap(args.id);
    if (typeof m$jmap == 'undefined') { console.log('m$jmap = undefined'); return };
    cmdo(args)
  });

  // Attach message handlers in shiny mode, correspond to API
  var fxns = ['addControl', 'addItem', 'addCmd']; //, 'addLayer'

  var addShinyHandler = function(fxn) {
    return function() {
      Shiny.addCustomMessageHandler(
        'amapro:' + fxn, function(message) {
          var el = document.getElementById(message.id);
          if (el) {
            delete message['id'];
            el.widget[fxn](message);
          }
        }
      );
    }
  };

  for (var i = 0; i < fxns.length; i++) {
    addShinyHandler(fxns[i])();
  }
}


/*
---------------------------------------
Original work Copyright 2021 Larry Helgason

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
---------------------------------------
*/
