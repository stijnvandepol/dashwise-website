<?xml version="1.0" encoding="UTF-8"?>
<!-- Makes /sitemap.xml readable in a browser. Search engines ignore this file. -->
<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:s="http://www.sitemaps.org/schemas/sitemap/0.9"
  xmlns:xhtml="http://www.w3.org/1999/xhtml">
  <xsl:output method="html" encoding="UTF-8" indent="yes"/>
  <xsl:template match="/">
    <html lang="en">
      <head>
        <meta charset="utf-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1"/>
        <meta name="robots" content="noindex"/>
        <title>Sitemap - Dashwise</title>
        <link rel="stylesheet" href="/assets/sitemap.css"/>
      </head>
      <body>
        <main>
          <h1>Sitemap</h1>
          <p>This is the XML sitemap of getdashwise.nl for search engines. It lists
            <xsl:value-of select="count(s:urlset/s:url)"/> pages.</p>
          <table>
            <thead>
              <tr><th>Page</th><th>Languages</th><th>Last changed</th></tr>
            </thead>
            <tbody>
              <xsl:for-each select="s:urlset/s:url">
                <tr>
                  <td><a href="{s:loc}"><xsl:value-of select="s:loc"/></a></td>
                  <td>
                    <xsl:for-each select="xhtml:link[@hreflang != 'x-default']">
                      <a class="lang" href="{@href}"><xsl:value-of select="@hreflang"/></a>
                    </xsl:for-each>
                  </td>
                  <td><xsl:value-of select="s:lastmod"/></td>
                </tr>
              </xsl:for-each>
            </tbody>
          </table>
          <p><a href="/">Back to getdashwise.nl</a></p>
        </main>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>
