/* Spatial math shared by DOM perspective, pointer rays and WebXR. Units: scene pixels. */
const SpatialGeometry={
 matrix(p,distance){return new DOMMatrix().translate(p.x,p.y-22,-distance-p.z+(p.depthBias||0)).rotateAxisAngle(0,1,0,p.ry).rotateAxisAngle(1,0,0,p.rx).rotateAxisAngle(0,0,1,p.rz).scale(p.scale);},
 ray(eye,x,y){const l=eye._layout,m=new DOMMatrix(getComputedStyle(l.world).transform).inverse(),r=eye.getBoundingClientRect(),a=new DOMPoint(0,0,1100).matrixTransform(m),b=new DOMPoint(x-r.left-r.width/2,y-r.top-r.height/2,0).matrixTransform(m);return {origin:[a.x,a.y,a.z],direction:[b.x-a.x,b.y-a.y,b.z-a.z]};},
 hit(ray,matrix){const inv=matrix.inverse(),o=new DOMPoint(...ray.origin).matrixTransform(inv),v=new DOMPoint(...ray.direction,0).matrixTransform(inv);if(Math.abs(v.z)<1e-8)return null;const t=-o.z/v.z;if(t<0)return null;const local={x:o.x+t*v.x,y:o.y+t*v.y},p=new DOMPoint(local.x,local.y,0).matrixTransform(matrix);return {...local,world:[p.x,p.y,p.z],t};},
 project(eye,point){const l=eye._layout,m=new DOMMatrix(getComputedStyle(l.world).transform),p=new DOMPoint(...point).matrixTransform(m),f=1100/(1100-p.z),r=eye.getBoundingClientRect();return [r.left+r.width/2+p.x*f,r.top+r.height/2+p.y*f];},
 css(p,distance){return `translate3d(${p.x}px,${p.y-22}px,${-distance-p.z+(p.depthBias||0)}px) rotateY(${p.ry}deg) rotateX(${p.rx}deg) rotateZ(${p.rz}deg) scale(${p.scale}) translate(-50%,-50%)`;}
};
