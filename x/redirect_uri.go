package x

import (
	"net/url"
	"regexp"

	"github.com/ory/fosite"
)

type redirectConfiguration interface {
	InsecureRedirects() []string
}

func IsRedirectURISecure(rc redirectConfiguration) func(redirectURI *url.URL) bool {
	return func(redirectURI *url.URL) bool {
		if fosite.IsRedirectURISecure(redirectURI) {
			return true
		}

		for _, allowed := range rc.InsecureRedirects() {
			if redirectURI.String() == allowed {
				return true
			} else if isMatched, err := regexp.MatchString(allowed, redirectURI.String()); err == nil && isMatched {
				return true
			}
		}

		return false
	}
}
