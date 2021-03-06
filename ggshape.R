Rotate2MidlineMatrix <- function (X, midline)
  {
    ## returns the rotation matrix that aligns a specimen saggital line
    ## to plane y = 0 (2D) or z = 0 (3D)
    ncl <- ncol (X) 
    Xm <- na.omit (X [midline, ])
    Mm <- matrix (apply (Xm, 2, mean), byrow = TRUE, nr = nrow (X), nc = ncl)
    Xc <- X - Mm 
    W <- na.omit (Xc [midline, ])
    RM <-svd (var (W))$v
    return (RM)
  }

ggshape <- function (shape, wireframe, colors, view = c(1, 2, 3),
                     rotation = c(1, 1, 1), culo = 0.015, thickness = 3,
                     palette = rev (brewer.pal (10, 'Spectral')))
  {
    Q <- shape
    Lms <- rownames (Q)
    Right <- grep ('-D', Lms)
    Left <- grep ('-E', Lms)
    Midline <- !(Lms %in% c (Lms [Right], Lms [Left]))
    Q <- Q %*% Rotate2MidlineMatrix (Q, Lms [Midline]) 
    Q <- Q %*% diag (rotation)
    if (all (view == c(1, 2, 3)))
      Q <- Q %*%
        array (c(cos(pi/7), sin (pi/7), 0,
                 -sin (pi/7), cos(pi/7), 0,
                 0, 0, 1), c(3, 3))
    colnames (Q) <- c('X', 'Y', 'Z')
    ## pts <- which (rownames (Q) %in% rownames (Q.tetra))
    Q <- Q [, view]
    colnames (Q) <- c('X', 'Y', 'Z')
    Q.tetra <- Q [wireframe, ]
    dim (Q.tetra) <- c (dim (wireframe), ncol (Q))
    Q.names <- array (rownames (Q) [wireframe], dim = dim (wireframe))
    Q.names <- apply (Q.names, 1, paste, collapse = '.')
    dimnames (Q.tetra) <- list('ild' = Q.names,
                               'pos' = c(1, 2),
                               'dim' = c('X', 'Y', 'Z'))

    Q.singular <- which (!duplicated (dimnames (Q.tetra) [[1]]))

    Q.colors <- rep (colors, times = 2) [Q.singular]

    Q.tetra <- Q.tetra [Q.singular, , ]

    Q.tetra.df <- dcast (melt (Q.tetra), ild ~ dim + pos)

    Q.tetra.df $ culo <- rep (culo, nrow (Q.tetra))

    #Q.tetra.df $ Z_1 <-
    #  (Q.tetra.df $ Z_1 - min (Q.tetra.df $ Z_1)) /
    #    (max (Q.tetra.df $ Z_1) - min (Q.tetra.df $ Z_1))

    #Q.tetra.df $ Z_2 <-
    #  (Q.tetra.df $ Z_2 - min (Q.tetra.df $ Z_2)) /
    #    (max (Q.tetra.df $ Z_2) - min (Q.tetra.df $ Z_2))
   
    Q.line.df <-
      plyr::ddply (Q.tetra.df, .(ild), plyr::summarise,
                   'X' = c(
                     X_1 - Z_1 * culo,
                     X_1 + Z_1 * culo,
                     X_2 + Z_2 * culo,
                     X_2 - Z_2 * culo),
                   'Y' = c(
                     Y_1,
                     Y_1,
                     Y_2,
                     Y_2))
    
    Q.line.df $ color <- rep (Q.colors, each = 4)
  
    shape.plot <-
      ggplot (data.frame(Q)) +
        geom_point (aes (x = X, y = Y), alpha = 0) +
          coord_fixed() +
            theme_minimal() +
              theme(plot.margin = unit(c(0, 0, 0, 0), 'cm')) +
                scale_x_continuous(breaks = NULL) +
                  scale_y_continuous(breaks = NULL) +
                    guides(size = FALSE) +
                      xlab('') + ylab('')

    shape.plot <-
      shape.plot +
        geom_polygon(aes (x = X, y = Y, group = ild, 
                          color = color, fill = color), Q.line.df, size = thickness)
    spec.pal <- colorRampPalette (palette, space = 'Lab')
    shape.plot +
      scale_color_gradientn('', colours = spec.pal(10)) +
        scale_fill_gradientn('', colours = spec.pal(10))
  }
