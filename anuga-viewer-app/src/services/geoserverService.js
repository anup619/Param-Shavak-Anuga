export const fetchAvailableLayers = async () => {
  try {
    const storesUrl = `/geoserver/rest/workspaces/anuga/coveragestores.json`;
    
    const username = 'admin';
    const password = 'geoserver';
    const basicAuth = 'Basic ' + btoa(username + ':' + password);
    
    const storesResponse = await fetch(storesUrl, {
      headers: {
        'Accept': 'application/json',
        'Authorization': basicAuth,
      },
    });

    if (!storesResponse.ok) {
      throw new Error(`Failed to fetch stores: ${storesResponse.status}`);
    }

    const storesData = await storesResponse.json();
    const stores = storesData.coverageStores?.coverageStore || [];
    
    // For each store, fetch its coverages (actual layer names)
    const allLayers = [];
    
    for (const store of stores) {
      const storeName = store.name;
      const coveragesUrl = `/geoserver/rest/workspaces/anuga/coveragestores/${storeName}/coverages.json`;
      
      const coveragesResponse = await fetch(coveragesUrl, {
        headers: {
          'Accept': 'application/json',
          'Authorization': basicAuth,
        },
      });
      
      if (coveragesResponse.ok) {
        const coveragesData = await coveragesResponse.json();
        const coverages = coveragesData.coverages?.coverage || [];
        coverages.forEach(cov => allLayers.push(cov.name));
      }
    }
    
    console.log("Available layers:", allLayers);
    return allLayers;
  } catch (error) {
    console.error("Error fetching layers:", error);
    return [];
  }
};