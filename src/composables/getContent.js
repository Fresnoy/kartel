import axios from "axios";

import config from "@/config";

import { ref } from "vue";

let content = ref([]);

let first = ref(20);
let after = ref("");
let hasNextPage = ref(true);

let load = ref(true);

/**
 * @type {string} url - url for the api request which combine url and query params from stringParams
 */
let url;
let stringParams;
let params = {};

/**
 *
 *  @param {object} params - the differents params to return
 *
 */
function setParams(params) {
  stringParams = "";
  for (let param in params) {
    params[param] && (stringParams = `${stringParams}&${params[param]}`);
  }
}

// Get artworks
// update params if filters change
// if the filters change reset artworks
class Content {
  // requests params setup
  static pageSize = 20;

  static requests = new Map();

  /**
   * Checks if the given lastRequest object is the same as the currentRequest object.
   *
   * @param {Object} lastRequest - The last request object to compare.
   * @param {Object} currentRequest - The current request object to compare.
   * @returns {boolean} - True if the lastRequest and currentRequest have the same id and type, false otherwise.
   */
  static isLastRequest(lastRequest, currentRequest) {
    return (
      lastRequest.id === currentRequest.id &&
      lastRequest.type === currentRequest.type
    );
  }

  constructor(type, parameters) {
    this.type = type;
    this.parameters = parameters;
    this.id = Content.requests.size + 1; //Requests counted
    this.url;

    this.setParamsByType(this.type, this.parameters);

    Content.requests.set(this.id, { type, id: this.id, url: this.url });
  }

  setParamsByType(type, parameters) {
    if (type === "artworks") {
      const { keywords, productionYear, type } =
        parameters;

      /**
       * Artwork parameters
       * @typedef {Object} params
       * @property {string} keywords
       * @property {string} productionYear
       * @property {string} type
       */
      params = {
        keywords: keywords ? `${keywords}` : null,
        productionYear: productionYear
          ? `${productionYear}`
          : null,
        type: type ? `${type}` : null,
      };

      setParams(params);


      // Build filters piece of query if there is any filter
      let arrayFilters = [""]

      if(params.keywords){
        arrayFilters.push(`hasKeywordName: "${params.keywords}"`)
      }
      if(params.productionYear){
        arrayFilters.push(`belongProductionYear: "${params.productionYear}"`)
      }
      if(params.type){
        arrayFilters.push(`hasType: "${params.type[0].toUpperCase() + params.type.slice(1).toLowerCase()}"`)
      }
      let filters = arrayFilters.join(", ")

      return (this.url = `query FetchArtworks {
        artworksPagination(first: ${first.value}, after: "${after.value}"${filters}) {
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

    } else if (type === "artists") {
      const { q, nationality, artist_type } = parameters;
      
      /**
       * Artist parameters
       * @typedef {Object} params
       * @property {string} query - q string from function parameters
       * @property {string} nationality
       */
      params = {
        query: q ? `q=${q}` : null,
        nationality: nationality ? `nationality=${nationality}` : null,
        artist_type: artist_type ? artist_type : "artworks__isnull=false",
      };

      setParams(params);

      return (this.url = `people/artist?page_size=${Content.pageSize}&page=${stringParams}`);
    }
  }
  /**
   * Fetches content from a given URL and type.
   * @param {string} url - The URL to fetch content from.
   * @param {string} type - The type of content to fetch.
   */
  async fetchContent(url, type) {
    try {
      // need to double verif before the second requests with contentData

      const response = await axios.post(`${config.v3_graph}`, {
          query: url
        }, {
          headers: {
            'Content-Type': 'application/json'
          }
        }
      );
      
      //Register data differently of it's filtered or not
      let data = {}
      // For calling all artworks after calling filters. Need to find a better solution
      // Calls of all artwork have tendencies to loop with the observer
      if (hasNextPage.value === false) {
        hasNextPage.value = response.data.data.artworksPagination.pageInfo.hasNextPage;
      }
      after.value = response.data.data.artworksPagination.pageInfo.endCursor;
      data = response.data.data.artworksPagination.edges.map(edge => edge.node)

      let pnv = { details: "Page non valide." }
      if (
        data &&
        Array.isArray(data) &&
        data !== pnv
      ) {
        let contentData;

        if (type === "artists") {
          contentData = await Promise.all(this.contentData(data));
        } else {
          contentData = data;
        }

        if (hasNextPage.value) {
          hasNextPage.value = response.data.data.artworksPagination.pageInfo.hasNextPage;
          content.value = [...content.value, ...contentData];
        }

        load.value = true;
      }

    } catch (err) {
      console.error(err);

      // catch 404
      if (err.response.status === 404) {
        load.value = false;
      }
    }

  }

  /**
   * Get the content data for each content in data and return a promise
   *
   * @param {Array<Object>} data - An array of data objects.
   * @returns {Array<Promise<Object>>} - An array of promises that resolve to the
   * transformed data objects. The promises may reject if the GET request fails.
   */
  contentData(data) {
    return data.map(async (data) => {
      try {
        const response = await axios.get(data.user);
        let userData = response.data;

        data.userData = userData;
        return data;
      } catch (err) {
        console.error(err);

        return data;
      }
    });
  }

  /**
   * Returns the last request of Content.
   *
   * @returns {object} The last request made, or undefined if no request was made.
   */
  getLastRequest() {
    return Array.from(Content.requests.values()).pop();
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

  // fetch the content with instance function (not doing that inside the constructor because can deal with async await)
  return await newContent.fetchContent(newContent.url, newContent.type);
}

// Need to reset this value in order to don't miss data
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
  setParams,
  stringParams,
};
