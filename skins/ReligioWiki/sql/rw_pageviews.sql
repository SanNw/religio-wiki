-- Religio Wiki — visualizações diárias por artigo, usadas por
-- {{#artigoemdestaque:}} (RwPageViews::renderFeaturedArticle) pra achar o
-- artigo mais lido do dia. Criada/atualizada por
-- maintenance/update.php via RwPageViews::onLoadExtensionSchemaUpdates
-- (ver LocalSettings-snippet.php).
CREATE TABLE IF NOT EXISTS /*_*/rw_pageviews (
	rwpv_date DATE NOT NULL,
	rwpv_title VARBINARY(255) NOT NULL,
	rwpv_views INT UNSIGNED NOT NULL DEFAULT 0,
	PRIMARY KEY (rwpv_date, rwpv_title)
) /*$wgDBTableOptions*/;
