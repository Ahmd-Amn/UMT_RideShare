const mapElement = document.getElementById('ride-map');

if (mapElement) {
  const status = document.getElementById('map-status');
  const key = mapElement.dataset.mapKey;
  const mode = mapElement.dataset.mapPage;
  const inputs = Object.fromEntries(['pickup', 'dropoff'].map(name => [name, {
    text: document.getElementById(`${name}_address`),
    lat: document.getElementById(`${name}_latitude`),
    lon: document.getElementById(`${name}_longitude`),
    suggestions: document.querySelector(`[data-place-suggestions="${name}"]`)
  }]));
  let active = 'pickup';
  let map;
  let routeLayer;
  let previewId = 0;
  const markers = {};

  if (key && window.L) {
    map = L.map(mapElement).setView([5.41, 103.09], 12);
    L.tileLayer(`https://maps.geoapify.com/v1/tile/osm-bright/{z}/{x}/{y}.png?apiKey=${encodeURIComponent(key)}`, {
      maxZoom: 20,
      attribution: 'Powered by <a href="https://www.geoapify.com/">Geoapify</a> | <a href="https://openmaptiles.org/">© OpenMapTiles</a> | <a href="https://www.openstreetmap.org/copyright">© OpenStreetMap contributors</a>'
    }).addTo(map);
  } else {
    status.textContent = 'Map unavailable. Check the map key and network connection.';
  }

  function point(name) {
    const item = inputs[name];
    return item.lat.value && item.lon.value ? [Number(item.lat.value), Number(item.lon.value)] : null;
  }

  function clearPoint(name) {
    previewId++;
    inputs[name].lat.value = '';
    inputs[name].lon.value = '';
    if (markers[name] && map) map.removeLayer(markers[name]);
    delete markers[name];
    if (routeLayer && mode === 'driver' && map) map.removeLayer(routeLayer);
  }

  function setPoint(name, lat, lon, label) {
    const item = inputs[name];
    item.text.value = label;
    item.lat.value = lat;
    item.lon.value = lon;
    item.suggestions.replaceChildren();
    item.text.setAttribute('aria-expanded', 'false');
    if (map) {
      if (markers[name]) map.removeLayer(markers[name]);
      markers[name] = L.marker([lat, lon], { title: `${name === 'pickup' ? 'Pickup' : 'Destination'}: ${label}` }).addTo(map);
      if (!point(name === 'pickup' ? 'dropoff' : 'pickup')) map.setView([lat, lon], 14);
    }
    if (mode === 'driver' && point('pickup') && point('dropoff')) previewRoute();
  }

  async function getJSON(url) {
    const response = await fetch(url, { credentials: 'same-origin' });
    const data = await response.json();
    if (!response.ok) throw new Error(data.detail || 'Map request failed.');
    return data;
  }

  async function previewRoute() {
    const id = ++previewId;
    const [pickupLat, pickupLon] = point('pickup');
    const [dropoffLat, dropoffLon] = point('dropoff');
    status.textContent = 'Calculating driving route…';
    try {
      const query = new URLSearchParams({ pickup_lat: pickupLat, pickup_lon: pickupLon, dropoff_lat: dropoffLat, dropoff_lon: dropoffLon });
      const { geometry } = await getJSON(`/api/route-preview?${query}`);
      if (id !== previewId) return;
      if (routeLayer && map) map.removeLayer(routeLayer);
      if (map) {
        routeLayer = L.geoJSON(geometry, { style: { color: '#3d711f', weight: 6 } }).addTo(map);
        map.fitBounds(routeLayer.getBounds(), { padding: [32, 32] });
      }
      status.textContent = 'Route ready. Passengers can see this path after you publish.';
    } catch (error) {
      if (id === previewId) status.textContent = error.message;
    }
  }

  document.querySelectorAll('[data-point-choice]').forEach(button => button.addEventListener('click', () => {
    active = button.dataset.pointChoice;
    document.querySelectorAll('[data-point-choice]').forEach(choice => {
      const selected = choice === button;
      choice.setAttribute('aria-pressed', String(selected));
      choice.classList.toggle('btn-dark', selected);
      choice.classList.toggle('btn-outline-dark', !selected);
    });
    status.textContent = `Click the map to set ${active === 'pickup' ? 'pickup' : 'destination'}.`;
  }));

  if (map) map.on('click', async event => {
    const { lat, lng } = event.latlng;
    const selected = active;
    setPoint(selected, lat, lng, `${lat.toFixed(5)}, ${lng.toFixed(5)}`);
    try {
      const query = new URLSearchParams({ lat, lon: lng });
      const { label } = await getJSON(`/api/places/reverse?${query}`);
      if (Number(inputs[selected].lat.value) === lat && Number(inputs[selected].lon.value) === lng) {
        inputs[selected].text.value = label;
        markers[selected].bindTooltip(label);
      }
    } catch (error) {
      status.textContent = 'Point selected. Address lookup is unavailable; coordinates will be used.';
    }
  });

  Object.entries(inputs).forEach(([name, item]) => {
    if (point(name) && map) setPoint(name, ...point(name), item.text.value);
    let timer;
    let searchId = 0;
    item.text.addEventListener('input', () => {
      clearPoint(name);
      item.suggestions.replaceChildren();
      item.text.setAttribute('aria-expanded', 'false');
      clearTimeout(timer);
      const query = item.text.value.trim();
      const id = ++searchId;
      if (query.length < 3) return;
      timer = setTimeout(async () => {
        try {
          const results = await getJSON(`/api/places?q=${encodeURIComponent(query)}`);
          if (id !== searchId) return;
          results.forEach(place => {
            const option = document.createElement('button');
            option.type = 'button';
            option.className = 'list-group-item list-group-item-action';
            option.textContent = place.label;
            option.addEventListener('click', () => setPoint(name, place.lat, place.lon, place.label));
            item.suggestions.append(option);
          });
          item.text.setAttribute('aria-expanded', String(results.length > 0));
          if (!results.length) status.textContent = 'No places found. Try another search or click the map.';
        } catch (error) {
          status.textContent = error.message;
        }
      }, 400);
    });
  });

  const routeData = document.getElementById('route-data');
  if (routeData && map) {
    const routes = JSON.parse(routeData.textContent);
    const layers = new Map(routes.map(ride => [String(ride.id), L.geoJSON(ride.geometry, { style: { color: '#71867a', weight: 4, opacity: .5 } }).addTo(map)]));
    const dialog = document.getElementById('route-dialog');
    let dialogMap;
    let dialogRoute;
    const showRoute = id => {
      layers.forEach((layer, routeId) => layer.setStyle({ color: routeId === id ? '#3d711f' : '#71867a', weight: routeId === id ? 6 : 4, opacity: routeId === id ? 1 : .35 }));
      const layer = layers.get(id);
      if (layer) map.fitBounds(layer.getBounds(), { padding: [32, 32] });
    };
    document.querySelectorAll('[data-show-route]').forEach(button => button.addEventListener('click', () => {
      const id = button.dataset.showRoute;
      const ride = routes.find(item => String(item.id) === id);
      if (!ride) return;
      showRoute(id);
      dialog.showModal();
      if (!dialogMap) {
        dialogMap = L.map('route-dialog-map');
        L.tileLayer(`https://maps.geoapify.com/v1/tile/osm-bright/{z}/{x}/{y}.png?apiKey=${encodeURIComponent(key)}`, {
          maxZoom: 20,
          attribution: 'Powered by <a href="https://www.geoapify.com/">Geoapify</a> | <a href="https://openmaptiles.org/">© OpenMapTiles</a> | <a href="https://www.openstreetmap.org/copyright">© OpenStreetMap contributors</a>'
        }).addTo(dialogMap);
      }
      if (dialogRoute) dialogMap.removeLayer(dialogRoute);
      dialogRoute = L.geoJSON(ride.geometry, { style: { color: '#3d711f', weight: 6 } }).addTo(dialogMap);
      requestAnimationFrame(() => {
        dialogMap.invalidateSize();
        dialogMap.fitBounds(dialogRoute.getBounds(), { padding: [32, 32] });
      });
    }));
    dialog.querySelector('[data-close-route]').addEventListener('click', () => dialog.close());
    if (routes.length) showRoute(String(routes[0].id));
  }

  document.querySelectorAll('[data-map-form]').forEach(form => form.addEventListener('submit', event => {
    if (point('pickup') && point('dropoff')) return;
    event.preventDefault();
    status.textContent = 'Select both locations from the suggestions or map.';
    inputs[point('pickup') ? 'dropoff' : 'pickup'].text.focus();
  }));
}
