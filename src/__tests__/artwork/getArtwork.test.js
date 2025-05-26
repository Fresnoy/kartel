import axios from "axios";

import {
  getArtwork,
  artwork,
  initValues,
} from "@/composables/artwork/getArtwork";

/**

  fixtures

**/
import artistFixture from "~/fixtures/artist.json";
import artworkFixture from "~/fixtures/artwork.json";

vi.mock("axios");

describe("test the composable getArtistInfo", () => {
  beforeEach(() => {
    axios.post.mockReset();
  });

  it("Init values", () => {
    initValues();
    expect(artwork.value).toEqual({});
  });

  it("Get artist's first artwork", async () => {
    axios.post
      .mockResolvedValue(
        // default mock but not the first
        {
          data: {
            default: true,
          },
        }
      )
      .mockResolvedValueOnce(artworkFixture)
      .mockResolvedValueOnce(artistFixture)

    let artworkId = artistFixture.data.data.artist.artworks[0].id;
    await getArtwork(artworkId);

    expect(axios.post).toHaveBeenCalledTimes(1);
    expect(artwork.value).toEqual(artworkFixture.data.data.artwork);
  });

  it("Get authors", async () => {
    axios.post
      .mockResolvedValue(
        // default mock but not the first
        {
          data: {
            default: true,
          },
        }
      )
      .mockResolvedValueOnce(artworkFixture)
      .mockResolvedValueOnce(artistFixture)
      .mockRejectedValueOnce({ mockMessage: "Error" });

    await getArtwork(artworkFixture.data.data.artwork.id);

    expect(axios.post).toHaveBeenCalledTimes(1);
    expect(artwork.value.authors).toEqual(artworkFixture.data.data.artwork.authors);
    expect(artwork.value.authors[0].id).toEqual(artistFixture.data.data.artist.id);
  });

  it("Get galleries", async () => {
    axios.post
      .mockResolvedValue(
        // default mock but not the first
        {
          data: {
            default: true,
          },
        }
      )
      .mockResolvedValueOnce(artworkFixture)
      .mockRejectedValue({ mockMessage: "Error" });

    await getArtwork(artworkFixture.data.data.artwork.id);

    expect(axios.post).toHaveBeenCalledTimes(1);
    expect(artwork.value.teaserGalleries).toEqual(artworkFixture.data.data.artwork.teaserGalleries);
    expect(artwork.value.inSituGalleries).toEqual(artworkFixture.data.data.artwork.inSituGalleries);
    expect(artwork.value.processGalleries).toEqual(artworkFixture.data.data.artwork.processGalleries);
    expect(artwork.value.pressGalleries).toEqual(artworkFixture.data.data.artwork.pressGalleries);
    expect(artwork.value.mediationGalleries).toEqual(artworkFixture.data.data.artwork.mediationGalleries);
  });

  it("Get diffusion events", async () => {
    axios.post
      .mockResolvedValue(
        // default mock but not the first
        {
          data: {
            default: true,
          },
        }
      )
      .mockResolvedValueOnce(artworkFixture)
      .mockRejectedValueOnce({ mockMessage: "Error" });

    await getArtwork(artworkFixture.data.data.artwork.id);

    expect(axios.post).toHaveBeenCalledTimes(1);
    expect(artwork.value.diffusions).toEqual(artworkFixture.data.data.artwork.diffusions);
  });

  it("Get artwork error", async () => {
    const errorMessage = 'Network Error';
    axios.post.mockResolvedValue(new Error(errorMessage))

    await getArtwork(errorMessage);

    expect(axios.post).toHaveBeenCalledTimes(1);
    expect(artwork.value).toEqual({});
  });
});
