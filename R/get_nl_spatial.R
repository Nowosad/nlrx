#' Calculate spatial data from metrics.turtles and metrics.patches output
#'
#' @description Execute NetLogo simulation from a nl object with a defined experiment and simdesign
#'
#' @param nl nl object
#' @param turtles if TRUE, the function generates spatial point objects (sf) from metrics.turtles data
#' @param patches if TRUE, the function generates raster objects from metrics.patches data
#' @param turtle_coords either "px" if turtle coordinates were measured as "pxcor" and "pycor" or "x" if coordinates were measured as "xcor" and "ycor"
#' @param format string indication wether to return spatial objects (RasterLayer, sf Points) or a rowbinded tibble
#' @return tibble with spatial data objects
#' @details
#'
#' get_nl_spatial generates spatial point objects and raster objects from tdata that has been collected by metrics.turtles and metrics.patches.
#' metrics.turtles and metrics.patches need to collect coordinates of turtles and patches.
#' For patches this can be easily done by adding "pxcor" and "pycor" to metrics.patches.
#' For turtles you can either add "pxcor" and "pycor" to metrics.turtles or "xcor" and "ycor".
#' It is also possible to measure both coordinates, and select the type that is used for spatial object creation through the function parameter turtle_coords.
#' "px" uses "pxcor" and "pycor", while "x" uses "xcor" and "ycor".
#'
#' @examples
#' \dontrun{
#'
#' # Run parallel on local machine:
#' future::plan(multisession)
#' # Run simulations:
#' results %<-% run_nl_all(nl = nl, cleanup = "all")
#' # Attach results to nl:
#' setsim(nl, "simoutput") <- results
#' # Get spatial data:
#' results_spatial <- get_nl_spatial(nl)
#'
#' }
#' @aliases get_nl_spatial
#' @rdname get_nl_spatial
#'
#' @export

get_nl_spatial <- function(nl,
                           turtles = TRUE,
                           patches = TRUE,
                           turtle_coords = "px",
                           format = "spatial"){

  if (!isTRUE(turtles)) {
    turtles <- tibble(id = seq(1, nrow(getsim(nl, "simoutput"))), turtles = rep(NA, nrow(getsim(nl, "simoutput"))))
  }


  if (!isTRUE(patches)) {
    patches <- tibble(id = seq(1, nrow(getsim(nl, "simoutput"))), patches = rep(NA, nrow(getsim(nl, "simoutput"))))
  }

  if (all(!is.na(getexp(nl, "metrics.patches"))) && isTRUE(patches)) {

    x_coord_ind <- grepl(c("pxcor"), names(getsim(nl, "simoutput")$metrics.patches[[1]]))
    x_coord_ind <- which(x_coord_ind == TRUE)
    y_coord_ind <- grepl(c("pycor"), names(getsim(nl, "simoutput")$metrics.patches[[1]]))
    y_coord_ind <- which(y_coord_ind == TRUE)

    patches_own <- which(1:ncol(getsim(nl, "simoutput")$metrics.patches[[1]]) != c(x_coord_ind, y_coord_ind))

    patches_own_names <- names(getsim(nl, "simoutput")$metrics.patches[[1]])[patches_own]

    patches <-  purrr::map(seq_along(getsim(nl, "simoutput")$metrics.patches), function(raster_ind){

        patches_raster <- raster::rasterFromXYZ(getsim(nl, "simoutput")$metrics.patches[[raster_ind]][,c(x_coord_ind,
                                                                                                         y_coord_ind,
                                                                                                         patches_own)])
        patches_raster <- raster::flip(patches_raster, 2)
        names(patches_raster) <- purrr::map_chr(patches_own_names, function(name){
          paste("S", getsim(nl, "simoutput")[raster_ind, "random-seed"],"_R",
                getsim(nl, "simoutput")[raster_ind, "siminputrow"],
                "_N", name,
                sep = "")
        })

        return(patches_raster)
      })

    patches_tib <- tibble::enframe(patches, "id", "patches")
    patches_tib$step <- getsim(nl, "simoutput")$`[step]`
    patches_tib$siminputrow <- getsim(nl, "simoutput")$siminputrow
    patches_tib$`random-seed` <- getsim(nl, "simoutput")$`random-seed`
  }

  if (all(!is.na(getexp(nl, "metrics.turtles"))) && isTRUE(turtles)) {

    turtles <-  purrr::map(seq_along(getsim(nl, "simoutput")$metrics.turtles), function(turtles_ind){

      if (turtle_coords == "px") {
        coord_ind <- grepl(c("pxcor|pycor"), names(getsim(nl, "simoutput")$metrics.turtles[[turtles_ind]]))
      }

      if (turtle_coords == "x") {
        coord_ind <- grepl(c("xcor|ycor"), names(getsim(nl, "simoutput")$metrics.turtles[[turtles_ind]]), fixed = TRUE)
      }

      turtles <- getsim(nl, "simoutput")$metrics.turtles[[turtles_ind]] %>%
        dplyr::mutate_at(which(coord_ind == TRUE), function(x) as.numeric(as.character(x))) %>%
        as.tibble %>%
        sf::st_as_sf(., coords = which(coord_ind == TRUE))

      # if (turtle_coords == "both") {
      #   if (turtle_coords == "px") {
      #     coord_ind_px <- grepl(c("pxcor|pycor"), names(getsim(nl, "simoutput")$metrics.turtles[[turtles_ind]]))
      #   }
      #
      #   if (turtle_coords == "x") {
      #     coord_ind_x <- grepl(c("xcor|ycor"), names(getsim(nl, "simoutput")$metrics.turtles[[turtles_ind]]), fixed = TRUE)
      #   }
      #
      #   turtles <- list("px" = sf::st_as_sf(getsim(nl, "simoutput")$metrics.turtles[[turtles_ind]], coords = which(coord_ind_px == TRUE)),
      #                   "x" = sf::st_as_sf(getsim(nl, "simoutput")$metrics.turtles[[turtles_ind]], coords = which(coord_ind_x == TRUE)))
      #
      #       }

      return(turtles)
    })

    turtles_tib <- tibble::enframe(turtles, "id", "turtles")
    turtles_tib$step <- getsim(nl, "simoutput")$`[step]`
    turtles_tib$siminputrow <- getsim(nl, "simoutput")$siminputrow
    turtles_tib$`random-seed` <- getsim(nl, "simoutput")$`random-seed`
  }

  nl_join <- dplyr::left_join(patches_tib, turtles_tib)

  if (format == "tibble") {

    if (!is.data.frame(patches)) {

      patches <- dplyr::mutate(patches_tib, maps = purrr::map(patches_tib$patches, function(x){
        # Create empty tibble with the same dimension as the raster ----
        grd <- tibble::as_tibble(expand.grid(x = seq(ceiling(raster::extent(x)[1]), floor(raster::extent(x)[2]), raster::res(x)[1]),
                                             y = seq(ceiling(raster::extent(x)[3]), floor(raster::extent(x)[4]), raster::res(x)[2])))
        # Fill with raster values ----
        patches_own_tib <- as.data.frame(raster::values(x))
        names(patches_own_tib) <- names(getsim(nl, "simoutput")$metrics.patches[[1]])[patches_own]
        grd <- dplyr::bind_cols(grd, patches_own_tib)
      })) %>%
        tidyr::unnest(maps) %>%
        dplyr::rename(patches_x = x,
                      patches_y = y)
    }

    if (!is.data.frame(turtles)) {
      turtles <- turtles_tib %>%
        unnest(turtles) %>%
        sf::st_as_sf()
      turtles <- turtles %>% sf::st_set_geometry(NULL) %>% cbind(sf::st_coordinates(turtles)) %>%
        dplyr::rename(turtles_x = X,
                      turtles_y = Y)
    }

    ## Bind tibbles:
    patches$group <- "patches"
    turtles$group <- "turtles"
    nl_join <- dplyr::bind_rows(patches, turtles) %>%
      dplyr::select(group, dplyr::everything())

  }

  return(nl_join)
}



