import axios from "axios";

import config from "@/config";

import { ref } from "vue";

// Data fetched
let content = ref([]);
// Number of elements displayed per page
let first = ref(20);
// The code of the following page
let after = ref("");
// If there is a next page
let hasNextPage = ref(false);
// The loader
let load = ref(true);

/**
 * @type {string} url - url for the api request which combine url and query params from stringParams
 */
let url;
let stringParams;
let params = {};

// Get artworks with and without filter
// Get artists with and without filter
// update params if filters change
// if the filters change update data
class Content {
  constructor(type, parameters) {
    this.type = type;
    this.parameters = parameters;
    this.url;

    this.setParams(this.parameters);
    this.filterPreparation();
    this.queryType(this.type)
  }

  /**
   *  Format parameters in order to serve as a filter
   *  @param {string} parameters - retrieve the parameters
   */
  setParams(parameters) {    
    let newParams = {}

    for (const [key, value] of Object.entries(parameters)) {
      newParams[key] = value? value : null;
    }

    params = newParams;
  }

  /**
   *  Prepare filter piece of query depending of the filters selected.
   * @returns {string} return the piece of query needed for filter.
   */
  filterPreparation() {
    let arrayFilters = [""];

    if (params.keywords) {
      arrayFilters.push(`hasKeywordName: "${params.keywords}"`);
    }
    if (params.productionYear) {
      arrayFilters.push(`belongProductionYear: "${params.productionYear}"`);
    }
    if (params.type) {
      arrayFilters.push(`hasType: "${params.type[0].toUpperCase() + params.type.slice(1).toLowerCase()}"`);
    }
    if (params.artist_type && params.artist_type != "<empty string>") {
      let typeName = params.artist_type[0].toUpperCase() + params.artist_type.substring(1);
      arrayFilters.push(`is${typeName}: true`);
    }
    let filters = arrayFilters.join(", ");

    return filters
  }

  /**
   *  Call the right query function according to the type displayed
   *  @param {string} type - the type, artworks or artists
   */
  queryType(type) {
    if (type === "artworks") {
      this.artworksQuery();
    } else if (type === "artists") {
      this.artistsQuery();
    }
  }

  /**
   * query fetching the artists.
   * @returns query needed to call the artists.
   */
  artistsQuery() {
    return (this.url = `
        query FetchArtists {
          artistsPagination(name: "", first: ${first.value}, after: "${after.value}"${this.filterPreparation()}) {
            edges {
              node {
                id
                displayName
                artistPhoto
                photo
              }
            }
            pageInfo {
              hasNextPage
              endCursor
            }
          }
        }
        `);
  }

  /**
   * query fetching the artworks.
   * @returns query needed to call the artworks.
   */
  artworksQuery() {
    return (this.url = `query FetchArtworks {
        artworksPagination(first: ${first.value}, after: "${after.value}"${this.filterPreparation()}) {
            edges {
              node {
                id
                title
                picture
              }
            }
            pageInfo {
              hasNextPage
              endCursor
            }
          }
        }`);
  }

  /**
   * Fetches content from a given URL and type.
   * @param {string} url - The URL to fetch content from.
   * @param {string} type - The type of content to fetch.
   */
  async fetchData(url, type) {
    try {
      const response = await axios.post(`${config.v3_graph}`, {
          query: url
        }, {
          headers: {
            'Content-Type': 'application/json'
          }
        }
      );

      let data = {}

      let paginationType = ""
      if (type === "artworks") {
        paginationType = "artworksPagination";
      } else if (type === "artists") {
        paginationType = "artistsPagination";
      }

      hasNextPage.value = response.data.data[paginationType].pageInfo.hasNextPage;
      data = response.data.data[paginationType].edges.map(edge => edge.node);

      this.handleDataPagination(data, response, paginationType);

      load.value = true;
    } catch (err) {
      console.error(err);

      // catch 404
      if (err.response.status === 404) {
        load.value = false;
      }
    }

  }

  /**
   * Handle behaviour according to page order concerned, mostly agregate current and new piece of data.
   * @param {string} data - last data loaded.
   * @param {string} response - data full response of the last data loaded (include endCursor and hasnextpage).
   * @param {string} paginationType - Type of pagination, here artworks of artists.
   */
  handleDataPagination(data, response, paginationType) {
    if (data &&
      Array.isArray(data)) {
      let contentData = data;

      let isAfterDifferentFromEndCursor = after.value !== response.data.data[paginationType].pageInfo.endCursor;
      // Agregate new page of data to the current data displayed
      // The second condition is here to avoid same data called twice.
      if (hasNextPage.value && isAfterDifferentFromEndCursor) {
        hasNextPage.value = response.data.data[paginationType].pageInfo.hasNextPage;
        content.value = [...content.value, ...contentData];
        after.value = response.data.data[paginationType].pageInfo.endCursor;
      } else {
        let isEndCursor = response.data.data[paginationType].pageInfo.endCursor;
        let isDataLeft = response.data.data[paginationType].edges != [];

        // Ensure last page of data are called
        // and call doesn't loop to the beginning again.
        if (hasNextPage.value === false && isEndCursor && isDataLeft) {
          content.value = [...content.value, ...contentData];
          after.value = response.data.data[paginationType].pageInfo.endCursor;
        }
      }
    }
  }

  /**
   * Get the content data for each content in data and return a promise.
   *
   * @param {Array<Object>} data - An array of data objects.
   * @returns {Array<Promise<Object>>} - An array of promises that resolve to the
   * transformed data objects. The promises may reject if the GET request fails.
   */
  contentData(data) {
      try {
        let filteredData = data.filter((user) => user.artist);
        let artistsArray = [];
        for (let i= 0; i < filteredData.length; i++){
          artistsArray.push(filteredData[i].artist)
        }
        data = artistsArray;
        return data;
      } catch (err) {
        console.error(err);

        return data;
      }
  }
}

/**
 * get a list of content by type
 *
 * @param {string} type
 * @param {object} parameters
 *
 * @example
 *
 *    getContent("artist",  params = {  query: "Something", nationality: "FR" })
 *
 */
async function getContent(type, parameters) {
  // need to pass the type of the get (artist or artwork) and set the params to match them

  // avoid load.value to be false if the observer is intersecting by default in large screen
  // !artworks.value[0] ? (load.value = true) : (load.value = false);
  load.value = false;

  // create a new content
  const newContent = new Content(type, parameters);

  // fetch the content with instance function
  // (not doing that inside the constructor because can deal with async await)
  return await newContent.fetchData(newContent.url, newContent.type);
}

/**
/* Need to reset this value in order to doesn't miss new data loads
*/
function resetData() {
  after.value = "";
}

/**
 *  @exports data for access outside
 */
export {
  content,
  getContent,
  resetData,
  load,
  url,
  params,
  stringParams,
};