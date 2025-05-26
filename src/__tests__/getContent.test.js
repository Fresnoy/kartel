import axios from "axios";

import {
  Content,
  getContent,
  resetData,
  content,
  load,
  params,
  after,
} from "@/composables/getContent";

import paginatedArtworkFixture from "~/fixtures/paginatedArtwork.json"
import paginatedArtistFixture from "~/fixtures/paginatedArtist.json"

let artworksParams = {
  keywords: null,
  productionYear: null,
  type: "film",
};

let artistsParams = {
  artist_type: null
};

// instance doesn't work with mock ?! axios.create results undefined
// https://runthatline.com/how-to-mock-axios-with-vitest/
vi.mock("axios");

// mockAxios.create = vi.fn(() => mockAxios)

describe("test the composable getContent", () => {
  beforeEach(() => {
    axios.post.mockReset();
    params.value = {};
    content.value = [];
    load.value = false;
    after.value = "";
  });

  it("check content for artwork", async () => {
    axios.post.mockResolvedValue(paginatedArtworkFixture);

    // check default value
    expect(content.value).toEqual([]);
    expect(load.value).toEqual(false);

    await getContent("artworks", artworksParams);

    // check value after running once getContent
    expect(content.value).toEqual(
      [{
      id: "1001",
      title: "Mémoire Fragmentée",
      picture: "http://127.0.0.1:8000/media/production/film/2021/07/dominati-juliette__0_ynC.png",
      type: "film"
    }]);
    expect(load.value).toEqual(true);

    expect(params).haveOwnProperty("type", artworksParams.type);
  });

  it("check content for artist", async () => {
    axios.post.mockResolvedValue(paginatedArtistFixture);

    // check default value
    expect(content.value).toEqual([]);
    expect(load.value).toEqual(false);

    await getContent("artists", artistsParams);

    expect(content.value).toEqual(
      [{
        id: 710,
        displayName: "Selestane",
        artistPhoto: "https://media.lefresnoy.net/?url=https://api.lefresnoy.net/media/people/fresnoyprofile/jmjh436g.jpg",
        photo: "https://media.lefresnoy.net/?url=https://api.lefresnoy.net/media/people/fresnoyprofile/jmjh436g.jpg"
      }]);
    expect(load.value).toEqual(true);
    
    expect(params).haveOwnProperty("artist_type", null);
  });

  it("catch on fetch fail", async () => {
    axios.post
      .mockRejectedValueOnce({
        response: {
          status: 403,
        },
      })
      .mockRejectedValueOnce({
        response: {
          status: 404,
        },
      });

    // check value after running once getContent with 403 error
    await getContent("artists", artistsParams);

    expect(content.value).toEqual([]);
    expect(load.value).toEqual(false);

    // check value after running once getContent with 404 error
    await getContent("artists", artistsParams);

    expect(content.value).toEqual([]);
    expect(load.value).toEqual(false);
  });

  it("preparate filter for keywords", () => {
    axios.post.mockResolvedValue(paginatedArtworkFixture);
    let parameters = { keywords: "3D" };

    const contentInstance = new Content(paginatedArtworkFixture, parameters);

    const filteredData = contentInstance.filterPreparation(params.value);

    expect(filteredData).toEqual(", hasKeywordName: \"3D\"");
  });

  it("preparate filter for production year", () => {
    axios.post.mockResolvedValue(paginatedArtworkFixture);
    let parameters = { productionYear: "2019" };

    const contentInstance = new Content(paginatedArtworkFixture, parameters);

    const filteredData = contentInstance.filterPreparation(params.value);

    expect(filteredData).toEqual(", belongProductionYear: \"2019\"");
  });

  it("preparate filter for type of production", () => {
    axios.post.mockResolvedValue(paginatedArtworkFixture);
    let parameters = { type: "Film" };

    const contentInstance = new Content(paginatedArtworkFixture, parameters);

    const filteredData = contentInstance.filterPreparation(params.value);

    expect(filteredData).toEqual(", hasType: \"Film\"");
  });

  it("preparate filter for the three artwork filters", () => {
    axios.post.mockResolvedValue(paginatedArtworkFixture);
    let parameters = { productionYear: "2019", keywords: "3D", type: "Film" };

    const contentInstance = new Content(paginatedArtworkFixture, parameters);

    const filteredData = contentInstance.filterPreparation(params.value);

    expect(filteredData).toEqual(", hasKeywordName: \"3D\", belongProductionYear: \"2019\", hasType: \"Film\"");
  });

  it("preparate filter for an artist type", () => {
    axios.post.mockResolvedValue(paginatedArtistFixture);
    let parameters = { artist_type: "student" };

    const contentInstance = new Content(paginatedArtistFixture, parameters);

    const filteredData = contentInstance.filterPreparation(params.value);

    expect(filteredData).toEqual(", isStudent: true");
  });

  it("have a none existing filter", () => {
    axios.post.mockResolvedValue(paginatedArtworkFixture);
    let parameters = { genre: "suspense" };

    const contentInstance = new Content(paginatedArtworkFixture, parameters);

    const filteredData = contentInstance.filterPreparation(params.value);

    expect(filteredData).toEqual("");
  });

  it("reset the after value", () => {
    after.value = "content";
    expect(after.value).toEqual("content");

    resetData();
    expect(after.value).toEqual("");
  });
});
