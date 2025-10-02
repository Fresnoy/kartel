// import all the dependencies of the app, pinia, router... for the test
// There might be a better way
// import "@/main";

import axios from "axios";

import config from "@/config";

import { ref } from "vue";

/**
 *  const which store and execute all the functions to fetch artist data
 *
 * @param {string} artistId (number id) - the id of the artist by the params url
 * @param {string} auth - the token of the user
 *
 */
// export const getArtistInfo = (artistId, auth) => {
/**
 * @type {object} artist
 * @type {array} artwork
 * @type {object} student
 * @type {object} user
 * @type {object} candidature
 */
let artist = ref();
let artworks = ref();
let student = ref();
let user = ref();
let candidature = ref();

/**
 *  set token and get user information with the id url of artist.user
 *  If the token is empty it's means that the user is not authenticated and set empty string.
 *
 * @type {string} token
 */
let token;

function initValues() {
  token = localStorage.getItem("token") || "";

  artist.value = {};
  artworks.value = [];
  student.value = {};
  user.value = {};
  candidature.value = {};
}

/**
 *  function for fetching artist data
 *
 * @param {string} id (number id) - the id of the artist
 *
 */
async function getArtist(id) {
  try {
    const response = await axios.post(`${config.v3_graph}`, {
      query:`
        query GetArtist {
          artist(id: ${id}) {
            id
            displayName
            firstName
            lastName
            artistPhoto
            photo
            nationality
            homelandCountry
            residencePhone
            homelandPhone
            residenceAddress
            socialInsuranceNumber
            cursus
            bioFr
            bioEn
            student {
              graduate
                promotion {
                  id
                  name
                }
            }
             websites {
              titleEn
              titleFr
              url
            }
            user {
              email
            }
              artworks {
              id
              title
              picture
            }
            studentApplication{
              id
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

    const data = response.data.data.artist;

    artist.value = data;
  } catch (err) {
    console.error(err);
    artist.value = {};
  }
}

/**
 *  function for fetching user data of artist
 *
 * @param {string} id (number id) - the id of the artist
 *
 */
async function getUser(id) {
  let headers = {
    "Content-Type": "application/json;charset=UTF-8",
  };

  if (!!token) {
    headers.Authorization = `JWT ${token}`;
  }

  try {
    const response = await axios.post(`${config.v3_graph}`, {
      query:`
        query GetUser {
          user(id: ${id}) {
            firstName
            lastName
          }
        }
      `
    }, {
      headers: {
        'Content-Type': 'application/json'
      }
    }
    );

    const data = response.data.data.user;

    user.value = data;
  } catch (err) {
    console.error(err);
    user.value = {};
  }
}

/**
 *  Fetch candidature from username
 *
 * @param {string} username - the username of the artist
 */
async function getCandidature(id) {
  try {
    const response = await axios.post(
      `${config.v3_graph}`, {
          query: `query GetCandidature {
                    studentApplication(id: ${id}) {
                      artist {
                        displayName
                        firstName
                        lastName
                        nationality
                        homelandCountry
                        residencePhone
                        homelandPhone
                        user {
                          email
                        }
                        residenceAddress
                        socialInsuranceNumber
                        cursus
                      }
                      curriculumVitae
                      identityCard
                      consideredProject1
                      consideredProject2
                      freeDocument
                      presentationVideo
                    }
                  }
                  `
        }, {
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `JWT ${token}`,
          }
        }
      );

    const data = response.data.data.studentApplication;

    candidature.value = data;
  } catch (err) {
    console.error(err);

    candidature.value = {};
  }
}

/**
 *  Fetch artwork data form the artist
 *
 * @param {string} id (number id) - the id of the artist
 *
 */
async function getArtworks(id) {
  try {
    // const response = await axios.get(`production/artwork?authors=${id}`);
    const response = await axios.post( `${config.v3_graph}`, {
      query:`
        query GetArtwork {
          artist(id: ${id}) {
            id
            firstName
            lastName
            displayName
            artworks {
              id
              title
              picture
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

    const data = response.data.data.artist.artworks;

    artworks.value = data;
  } catch (err) {
    console.error(err);
    artworks.value = [];
  }
}

/**
 *  Fetch student data of the artist
 *
 * @param {string} id (number id) - the id of the artist
 *
 */
async function getStudent(id) {
  try {
    const response = await axios.post( `${config.v3_graph}`, {
        query:`
          query GetStudent {
            artist(id: ${id}) {
              id
              student {
                id
              }
            }
          }
        `
      } , {
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );

    const studentData = response.data.data.artist.student;

    // return if no student data -> that means that the artist is not a student
    if (!studentData || studentData.length === 0) {
      student.value = [];
      return;
    }

    student.value = studentData;
  } catch (err) {
    console.error(err);
    student.value = {};
  }
}

async function setup(artistId, auth) {
  initValues();

  // await the artist data for get the user url to not exec the function getUser inside
  await getArtist(artistId);

  await getUser(artistId);

  if (auth) {
    // get the studentapplication (array) max id value
    console.log(artist.value.studentApplication);
    if (artist.value.studentApplication) {
      let maxId = artist.value.studentApplication.map(app => app.id).reduce((a, b) => Math.max(a, b), 0);
      console.log(maxId)
      getCandidature(maxId);
    }
  }

}

/**
 *  @exports data for access outside
 */
export {
  setup,
  // define access to the ref needed inside the template
  artist,
  user,
  artworks,
  student,
  candidature,

  // export functions for test
  initValues,
  getArtist,
  getUser,
  getArtworks,
  getStudent,
  getCandidature,
};
// };
