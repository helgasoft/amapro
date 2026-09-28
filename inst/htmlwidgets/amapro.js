/*
  amapro.js -- HTMLWidgets binding that turns R commands into AMap / Loca
  JavaScript calls via eval(). Flow:

    am.cmd(id, cmd, trgt, param1=...)        -> args.data holds {param1, ...}
    am.cmd(id, 'set', 'ImageLayer', name='m$imLay', url='https://..')
                                              -> args.data holds {name, url, ...}
    am.cmd(id, 'getZoom', 'map', r='gZum')   -> result is sent to Shiny input gZum

  cmdo() builds one JS statement (as a string) from args, then cmdType()
  switches on args.trgt to apply type-specific handling before eval'ing it,
  e.g. for a Loca layer:
     stmt = objName+'= new Loca.'+target+'(args.data); m$loca.add('+objName+');';
     sval(stmt, args);

  Dynamically named elements (the R side's `name=`, tagged internally as
  `iname` for items added via am.item()) are intentionally created as bare
  (undeclared) globals by the eval'd code, so later commands can refer to
  them by that same name (e.g. am.cmd('open', 'iwin', ...) after
  am.cmd('set', 'InfoWindow', name='iwin', ...)). `mdata` and `tefu` are also
  intentionally kept as real globals for the same reason -- see the comments
  at their definitions in cmdType()/cmdo().
*/
var debug = false;

HTMLWidgets.widget({

  name: 'amapro',
  type: 'output',

  factory: function (el, width, height) {

    let initialized = false;
    let opts;

    return {

      renderValue: function (x) {

        if (typeof AMap === 'undefined') {
          alert("Check for AMap library file 'amap.js' and try again");
          return;
        }
        if (x.hasOwnProperty('debug')) debug = x.debug;   // keep: 'debug:false' must still reset it

        window.m$jmap = new AMap.Map(document.getElementById(el.id), x.opts);

        if (x.loca) {
          if (typeof Loca === 'undefined') {
            alert('Check for Loca library and try again');
            return;
          }
          window.m$loca = new Loca.Container({ map: m$jmap });
        }

        if (!initialized) {
          initialized = true;
          setEvents(x.opts, 'm$jmap');
          //if (m$loca) setEvents?
        }

        if (x.api) {
          // after initialization, call any outstanding API functions queued
          // while the widget was built via the pipe chain (per D.Attali)
          x.api.forEach(call => {
            const method = call.method;
            delete call.method;
            try { this[method](call); } catch (err) {}
          });
        }

      },   // end renderValue

      addControl: function (args) {
        const hasArgs = !(typeof args.data === 'object' && args.data.length === 0);
        const stmt = `m$jmap.addControl(new AMap.${args.ctype}(${hasArgs ? 'args.data' : ''}));`;
        sval(stmt, args);
      },

      addItem: function (args) {
        if (args.data.name) {                 // replace name with iname
          args.data.iname = args.data.name;   // tag as coming from addItem
          delete args.data.name;
        }
        args.cmd = 'set';
        args.trgt = args.itype;
        cmdo(args);
      },

      addCmd: function (args) {    // from am.cmd(cmd, target, etc)
        cmdo(args);
      },

      getjmap: function () { return m$jmap; },

      getOpts: function () { return opts; },

      resize: function (width, height) {
        if (m$jmap) m$jmap.resize({ width, height });
      }

    };
  }
});

function get_amap(id) {
  const w = HTMLWidgets.find('#' + id);
  return w ? w.getjmap() : null;
}

function get_amap_opts(id) {
  const w = HTMLWidgets.find('#' + id);
  return w ? w.getOpts() : null;
}

function setPrelims(args) {
  if (args.data.bounds) {          // Rectangle corners: SouthWest, NorthEast
    const b = args.data.bounds;
    args.data.bounds = new AMap.Bounds(b[0], b[1]);
  }
  if (args.data.icon && typeof args.data.icon === 'string' && !args.data.icon.startsWith('http')) {
    sval(`args.data.icon=${args.data.icon};`, args);   // named icon: a bare JS expression, not a URL
  }
  return args;
}

function setEvents(adata, objName) {
  if (!objName) { console.log('missing object name, has events'); return; };
  const bind = (list, method) => {
    for (let i = 0; i < list.length; i++) {
      const event = list[i].e || null;
      const handler = list[i].f || null;
      if (!event || !handler) { console.log('missing event name or handler'); return; }   // stop this list only
      const query = list[i].q || '';
      sval(`${objName}.${method}('${event}', ${query}${handler}); `, null);
    }
  };
  if (adata.on) bind(adata.on, 'on');
  if (adata.off) bind(adata.off, 'off');
}

const getCircularReplacer = () => {   // for stringify
  const seen = new WeakSet();
  return (key, value) => {
    if (typeof value === 'object' && value !== null) {
      if (seen.has(value)) {
        return; // returns undefined, which removes the key from the JSON output
      }
      seen.add(value);
    }
    return value;
  };
};

function sval(str, args, quiet = false) {
  try {
    eval(str);
    if (debug && !quiet) {
      const info = JSON.stringify(args, getCircularReplacer());
      console.log(`eval(${str})  args=${info}`);
    }
  } catch (err) {
    console.log(`error:${str} \n ${err.message}`);
    return false;
  }
  return true;
}

// true when every key looks like an array index ("0","1",...) - i.e. this
// object represents an unnamed (positional) R list rather than named args
function isPositional(data) {
  return !Object.keys(data).some(isNaN);
}

// Turn an unnamed args array into the literal "(...)" text that follows the
// constructor/method name in the generated statement. Bare expressions that
// already resolve to something (existing variables, numbers, nested
// coordinate arrays) are kept unquoted; anything else is quoted as a plain
// string.
function buildPositionalArgList(list) {
  let out = '(';
  list.forEach(x => {
    let item = sval(x, null, true) ? x : `"${x}"`;
    if (typeof item === 'object' && item.length) {     // nested array, e.g. a coordinate pair
      let inner = '[';
      item.forEach(y => { inner += (eval(y) ? y : `"${y}"`) + ','; });
      item = inner.replace(/.$/, ']');
    }
    out += item + ',';
  });
  if (out === '(') out = '(z';           // becomes '();' for clean(), hide(), etc.
  return out.replace(/.$/, ');');
}

function cmdo(args) {
  // from addItem or addCmd
  if (args.cmd === 'addTo') args.cmd = 'add';    // do not use AMap's own addTo(map)
  args = setPrelims(args);

  let objName = args.data.name;
  if (objName) delete args.data.name;

  // convert from string to function if any
  Object.entries(args.data).forEach(([k, v]) => {
    if (v.toString().startsWith('function')) eval(`args.data.${k} = ${v};`);
  });

  if (args.trgt === '' || args.trgt === 'map') args.trgt = 'm$jmap';

  let argList = '(args.data);';

  if (isPositional(args.data)) args.data = Object.values(args.data);   // unnamed only

  if (Array.isArray(args.data)) {                          // [1,2,..] positional args
    argList = buildPositionalArgList(args.data);
  } else if (args.cmd.startsWith('set') && args.cmd.length > 3 &&
      !'setOptions setParams setIcon setText setStyle setFitView'.includes(args.cmd)) {
    argList = args.cmd.indexOf('(') > 0 ? '' : '(...Object.values(args.data))';   // setZoomAndCenter, setRotation, etc.
  }

  if (args.cmd.startsWith('get')) {           // changes .source - keep code here
    if (args.cmd.indexOf('(') > 0) argList = ';';      // params already inside cmd
    args.trgt = `var tmp=${args.trgt}`;
    if (!args.data.f) args.data.f = 'function(x) {return x;}';
    sval(`tefu= ${args.data.f}`, args, true);          // set the function to apply -- tefu is
                                                        // intentionally global: the statement built
                                                        // below calls it by that bare name
    const inputName = args.data.r;                     // Shiny input name to publish the result to
    delete args.data.r; delete args.data.f;            // don't interfere with real getX params
    argList += ` tmp= tefu(tmp); Shiny.setInputValue('${inputName}', tmp)`;
  }

  let stmt;
  switch (args.cmd) {
    case 'set':
      if (objName) {
        stmt = `${objName}= new AMap.${args.trgt}${argList}`;
      } else if (args.data.iname) {             // comes from addItem
        objName = args.data.iname;              // keep for events, if any
        delete args.data.iname;
        stmt = `${objName}= new AMap.${args.trgt}${argList}m$jmap.add(${objName});`;
      } else {
        argList = argList.replace(');', '));');
        stmt = `m$jmap.add(new AMap.${args.trgt}${argList}`;
      }
      break;
    case 'code':
      stmt = args.trgt;
      break;
    case 'prop':
      stmt = `${args.trgt}.${Object.keys(args.data)[0]}=Object.values(args.data)[0];`;
      break;
    case 'var':
      stmt = `${args.trgt}=args.data[0];`;
      break;
    default:
      stmt = `${args.trgt}.${args.cmd}${argList}`;
  }

  cmdType(stmt, args, objName);

  if (args.data.on || args.data.off)
    setEvents(args.data, objName);  // handle events:  objName.on('event', func)
}

function cmdType(baseStmt, args, objName) {
  if (args.cmd === 'code') { sval(baseStmt, args); return; }

  const target = args.trgt.replace('window.', '');    // simplify switch argument
  let stmt;

  switch (target) {

    // case 'HawkEye':    // plugin not included in our amap.js
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
    // case 'VideoLayer':    // only v.1.4
    case 'VectorLayer':
    case 'LabelsLayer':
    case 'convertFrom':
      sval(baseStmt, args);
      break;

    case 'GeoJSON':
      if (!args.data.getPolygon) {    // set default getPolygon function
        args.data.getPolygon = function (geojson, lnglats) {
          //var area = AMap.GeometryUtil.ringArea(lnglats[0]); console.log(area);
          const params = Object.assign({}, args.data);
          delete params['geoJSON'];
          params.path = lnglats;
          return new AMap.Polygon(params);
          //  {path: lnglats, fillOpacity: 0.3, strokeWeight:2, strokeColor:'magenta', fillColor:'red', zIndex:15});
        };
      }
      sval(baseStmt, args);
      break;

    case 'Marker':
      if (!args.data.icon) {
        args.data.icon = 'https://a.amap.com/jsapi_demos/static/demo-center/icons/poi-marker-default.png';
        args.data.offset = new AMap.Pixel(-25, -50);
      }
      sval(baseStmt, args);
      break;

    case 'MassMarks':
      if (!args.data.data) break;
      window.mdata = Object.values(args.data.data);   // intentionally global: named directly
                                                        // inside the eval'd statement below
      delete args.data.data;

      if (!args.data.style) {   // set default style
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
      }
      stmt = objName
        ? `${objName}= new AMap.MassMarks(mdata, args.data);`
        : 'm$massmarks= new AMap.MassMarks(mdata, args.data); m$massmarks.setMap(m$jmap);';
      sval(stmt, args);
      break;

    case 'Satellite':
    case 'RoadNet':
    case 'Traffic':
    case 'Flexible':

    // 3 LOCA TileLayers
    // case 'MapboxVectorTileLayer':   // plugin:  https://lbs.amap.com/demo/javascript-api-v2/example/thirdlayer/mvt-layer
    case 'WMS':
    case 'WMTS':
      if (objName) {
        stmt = eval(`typeof ${objName}=='undefined'`)
          ? `${objName}= new AMap.TileLayer.${target}(args.data); `
          : '';                        // name exists already
        stmt += `${objName}.setMap(m$jmap);`;
      } else {
        const autoName = 'm$' + target.toLowerCase();
        stmt = `${autoName}= new AMap.TileLayer.${target}(args.data); ${autoName}.setMap(m$jmap);`;
      }
      sval(stmt, args);
      break;


    case '3DTilesLayer':      // https://lbs.amap.com/demo/javascript-api-v2/example/selflayer/3dtileslayer
      // needs plugin=AMap.3DTilesLayer  + GLTFLoader.117.min.js + three.117.js
      args.data.map = m$jmap;
      stmt = `${objName}= new AMap.TileLayer['${target}'](args.data); `;
      sval(stmt, args);
      break;

    case 'HeatMap': {
      if (args.data.ddd) {   // R dislikes '3d' name
        args.data['3d'] = args.data.ddd;
        delete args.data.ddd;
      }
      if (!args.data.pnts) { console.log(target + ' has no data'); break; }

      let srcExpr;
      if (typeof args.data.pnts === 'string') {   // when heatmapData.js in header
        srcExpr = 'data:' + args.data.pnts;
      } else {                                    // actual points
        args.pnts = args.data.pnts;                // clean opts
        srcExpr = 'data:args.pnts';
      }
      delete args.data.pnts;

      stmt = '';
      if (eval(`typeof ${objName}=='undefined'`)) {
        stmt = `${objName}= new AMap.${target}(m$jmap, args.data); `;
        stmt += `${objName}.setDataSet({${srcExpr}, max:100}); `;
      }
      //stmt = stmt + objName + ".show();"
      sval(stmt, args);
      break;
    }

    case 'Buildings':       // 3D buildings inside China only
    case 'MapboxVectorTileLayer': {
      const autoName = 'm$' + target;
      stmt = `${autoName}= new AMap.${target}(args.data); ${autoName}.setMap(m$jmap);`;
      sval(stmt, args);
      break;
    }

    case 'LayerGroup': {   // for TileLayers only?
      // baseStmt looks like 'm$jmap.add(new AMap.LayerGroup([layer1,layer2]));'
      const autoName = 'm$' + target;
      stmt = baseStmt.replace('m$jmap.add(', autoName + '= ').replace('));', '); ' + autoName + '.setMap(m$jmap);');
      sval(stmt, args);
      break;
    }

    case 'OverlayGroup':   // for overlays (Marker,Circle,OverlayGroup,etc)
      stmt = baseStmt;
      if (stmt.indexOf('[') === -1) {
        stmt = stmt.replace(target + '(', target + '([');
        stmt = stmt.indexOf('));') === -1 ? stmt.replace(');', ']);') : stmt.replace('));', ']));');
      }
      sval(stmt, args);
      break;

    case 'MouseTool':
      if (args.cmd === 'close') {
        m$jmap.remove(overlays);
        window.overlays = [];
        window.m$mousetool.close(true);
        window.m$mousetool = undefined;   // allow map to pan again
        break;
      }
      if (typeof window.m$mousetool === 'undefined') {
        window.overlays = [];
        window.m$mousetool = new AMap.MouseTool(m$jmap);
        window.m$mousetool.on('draw', function (e) { overlays.push(e.obj); });
      }
      stmt = `m$mousetool.${args.cmd}(args.data);`;
      sval(stmt, args);
      break;

    case 'CanvasLayer':
      if (!objName) break;
      if (!args.data.bounds) break;
      if (args.data.canvas) args.data.canvas = eval(args.data.canvas);
      sval(baseStmt, args);
      break;


    // LOCA elements ---------------------------------------

    case 'Container':
      if (objName) break;  // unique name m$loca
      stmt = 'm$loca = new Loca.Container({ map: m$jmap });';
      sval(stmt, args);
      break;

    case 'GeoJSONSource':
      if (!objName) break;
      // data: geojson object OR url: 'http..'
      stmt = args.data.data
        ? `${objName}= new Loca.GeoJSONSource({data: args.data.data}); `
        : `${objName}= new Loca.GeoJSONSource({url:'${args.data.url}'}); `;
      sval(stmt, args);
      break;

    case 'ScatterLayer':      // animation layers
    case 'PulseLinkLayer':
    case 'PulseLineLayer':
    case 'LaserLayer':

    case 'PointLayer':      // base
    case 'IconLayer':
    case 'ZMarkerLayer':
    case 'PrismLayer':
    case 'LineLayer':
    case 'LinkLayer':
    case 'PolygonLayer':
    case 'HeatMapLayer':
    case 'HexagonLayer':
    case 'GridLayer':

    case 'GltfLayer':     // undocumented
    case 'GeoBufferSource':
    case 'Legend':
    case 'ViewControl': {  // see https://lbs.amap.com/demo/loca-v2/demos/cat-view-control/view-control
      if (!objName) break;
      const argCount = Array.isArray(args.data) ? args.data.length : Object.keys(args.data).length;
      const argExpr = argCount === 0 ? '{}' : 'args.data';
      // layer is added to the Loca container the same way an AMap item is
      // added to m$jmap in cmdo()'s 'set' branch above
      stmt = `${objName}= new Loca.${target}(${argExpr}); m$loca.add(${objName});`;
      sval(stmt, args);
      break;
    }

    case 'AmbientLight':        // for newer loca.js
    case 'DirectionalLight':
    case 'PointLight':
      if (!objName) break;
      stmt = `${objName}= new Loca.${target}(args.data); m$loca.addLight(${objName});`;
      sval(stmt, args);
      break;

    case 'Dat':         // see https://lbs.amap.com/demo/loca-v2/demos/cat-polygon/bj-airport
    case 'ambLight':
    case 'dirLight':
    case 'pointLight':
      stmt = `m$loca.${target} = args.data;`;
      sval(stmt, args);
      break;

    default:
      sval(baseStmt, args);

  }  // end switch
}

if (HTMLWidgets.shinyMode) {

  Shiny.addCustomMessageHandler('amapro:doCmd', args => {
    const mapInstance = get_amap(args.id);
    if (typeof mapInstance === 'undefined') { console.log('m$jmap = undefined'); return; }
    cmdo(args);
  });

  // Attach message handlers in shiny mode, correspond to API
  ['addControl', 'addItem', 'addCmd'].forEach(fxn => {
    Shiny.addCustomMessageHandler('amapro:' + fxn, message => {
      const el = document.getElementById(message.id);
      if (el) {
        delete message.id;
        el.widget[fxn](message);
      }
    });
  });
}


/*
---------------------------------------
Original work Copyright 2022-2027 Larry Helgason

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
