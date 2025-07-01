/**
 * Config
 */
import axios from "axios";
import config from "@/config";

/**
 * Modules
 */
import { ref } from "vue";

/**
 * @type {object} artwork - the artwork
 */
let artwork = ref();

/**
 * Initializes the values of the artwork
 * events variables to empty objects or arrays.
 */
function initValues() {
  artwork.value = {};
}

/**
 * Get the artwork and run all the function to get the rest of info
 *
 * @param {number} id - id of the artwork
 */
async function getArtwork(id) {
  initValues();

  try {
    // const response = await axios.get(`production/artwork/${id}`);
    const response = await axios.post( `${config.v3_graph}`, {
      query: `
        query GetArtwork {
          artwork(id: ${id}) {
            title
            picture
            type
            productionDate
            descriptionFr
            descriptionEn
            creditsFr
            creditsEn
            thanksFr
            thanksEn
            authors {
              id
              displayName
            }
            collaborators {
              staffName
              taskName
              task {
                label
                description
              }
            }
            partners {
              taskName
              name
            }
            diffusions {
              event {
                title
              }
            }
            teaserGalleries {
              label
              description
              media {
                picture
              }
            }
            inSituGalleries {
              label
              description
              media {
                picture
              }
            }
            processGalleries {
              label
              description
              media {
                picture
              }
            }
            pressGalleries {
              label
              description
              media {
                picture
              }
            }
            mediationGalleries {
              label
              description
              media {
                picture
              }
            }
          }
        }
      `
      }, {
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );

    const data = response.data.data.artwork;

    artwork.value = data;

  } catch (err) {
    console.error(err);
  }
}

export {
  getArtwork,
  artwork,
  initValues,
};
