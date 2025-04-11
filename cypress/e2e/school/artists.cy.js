import config from "../../../src/config";

describe("Artists", () => {
  it("intercept request of artists", () => {
    //get url path by config !!!

    // intercept any request of /v2/people/artist
    cy.intercept(`${config.rest_uri_v2}people/artist*`).as("artists");
    cy.intercept(`${config.rest_uri_v2}people/user/*`).as("artistUser");

    cy.visit("/artists");

    cy.wait("@artists").then(({ response }) => {
      expect(response.statusCode).to.eq(200);
      expect(response.body).to.exist;
    });

    cy.wait("@artistUser").then(({ response }) => {
      expect(response.statusCode).to.eq(200);
      expect(response.body).to.exist;
    });

    // check if body exist and if each element of it contains rights properties
  });
});
